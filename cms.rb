require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map { |file| File.basename(file) }
end

get "/" do
  @title = "Index"
  erb :index
end

get "/new" do
  redirect_to_index unless signed_in?
  erb :new
end

get "/signin" do
  if session[:signin]
    session[:error_message] = "You are already signed in."
    redirect "/"
  else
    erb :signin
  end
end

get "/signup" do
  if session[:signin]
    session[:error_message] = "You are already signed in."
    redirect "/"
  else
    erb :signup
  end
end

get "/:filename" do
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  if File.exist?(file_path)
    load_file_body(filename, file_path)
  else
    session[:error_message] = "#{filename} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  redirect_to_index unless signed_in?
  @filename = params[:filename]
  file_path = File.join(data_path, @filename)
  if File.exist?(file_path)
    @file_body = File.read(file_path)
    erb :edit
  else
    session[:error_message] = "#{@filename} does not exist."
    redirect "/"
  end
end

post "/new" do
  redirect_to_index unless signed_in?
  filename = params[:filename]
  if filename == "" || (filename =~ /\.txt$|\.md$/) == nil
    session[:error_message] = "You must enter a file name."
    redirect "/new"
    halt
  end
  file_path = File.join(data_path, filename)
  File.write(file_path, "")
  session[:error_message] = "#{filename} has been created."
  redirect "/"
end

post "/new_image" do
  image = params[:image]
  File.open("#{data_path}/#{image[:filename]}", "w") { |f| f.write(image[:tempfile].read) }
  redirect "/"
end

post "/signin" do
  file_path = File.join(credentials_path, "users.yml")
  credentials = YAML.load_file(file_path)
  bcrypt_password = BCrypt::Password.new(credentials[params[:username]])
  if bcrypt_password == params[:password]
    session[:signin] = params[:username]
    session[:error_message] = "Welcome!"
    redirect "/"
  else
    session[:error_message] = "Invalid Credentials"
    status 422
    erb :signin
  end
end

post "/signup" do
  username = params[:username]
  password_hash = BCrypt::Password.create(params[:password])
  user = { username => password_hash }
  users = File.join(credentials_path, "users.yml")
  File.open(users, "a") { |f| f.write user.to_yaml }
end

post "/signout" do
  session[:error_message] = "#{session[:signin]} has been signed out."
  session[:signin] = false
  redirect "/"
end

post "/:filename/delete" do
  redirect_to_index unless signed_in?
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  File.delete(file_path)
  session[:error_message] = "#{filename} has been deleted."
  redirect "/"
end

post "/:filename" do
  redirect_to_index unless signed_in?
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  File.write(file_path, params[:edited_file])
  session[:error_message] = "#{filename} has been updated."
  redirect "/"
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_body(filename, file_path)
  if File.extname(filename) == ".md"
    headers["Content-Type"] = "text/html"
    erb render_markdown(File.read(file_path))
  else
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def credentials_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test", __FILE__)
  else
    File.expand_path("..", __FILE__)
  end
end

def redirect_to_index
  session[:error_message] = "You must be signed in to do that."
  redirect "/"
end

def signed_in?
  !!session[:signin]
end
