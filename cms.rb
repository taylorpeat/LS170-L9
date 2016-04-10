require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @files = Dir.glob("data/*.txt").map { |file| File.basename(file) }
end

get "/" do
  @title = "Index"
  erb :index
end

get "/:filename" do
  if File.exist?("data/#{params[:filename]}")
    headers["Content-Tyoe"] = "text/plain"
    File.read("data/#{params[:filename]}")
  else
    session[:error_message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end