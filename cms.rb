require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'

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

post "/:filename" do
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  File.write(file_path, params[:edited_file])
  session[:error_message] = "#{params[:filename]} has been updated."
  redirect "/"
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_body(filename, file_path)
  if File.extname(filename) == ".md"
    headers["Content-Type"] = "text/html"
    render_markdown(File.read(file_path))
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
