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
  if File.exist?("data/#{filename}")
    load_file_body(filename)
  else
    session[:error_message] = "#{filename} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  @filename = params[:filename]
  file_path = File.join(data_path, @filename)
  if File.exist?("data/#{@filename}")
    @file_body = load_file_body(@filename)
    erb :edit
  else
    session[:error_message] = "#{@filename} does not exist."
    redirect "/"
  end

end

post "/:filename" do
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  File.write("data/#{filename}", params[:edited_file])
  session[:error_message] = "#{params[:filename]} has been updated."
  redirect "/"
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_body(filename)
  if File.extname(filename) == ".md"
    headers["Content-Tyoe"] = "text/html"
    render_markdown(File.read("data/#{filename}"))
  else
    headers["Content-Tyoe"] = "text/plain"
    File.read("data/#{filename}")
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end
