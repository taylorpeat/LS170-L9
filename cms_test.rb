ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "cms"

class AppTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "history.txt")
  end

  def test_history
    get "/history.txt"
    assert_equal File.read("data/history.txt"), last_response.body
  end

  def test_no_file
    get "/wrong.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "wrong.txt does not exist."
  end
end