ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require 'fileutils'

require "../cms"

class AppTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
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

  def test_markdown
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<em>"
  end

  def test_editing
    get "/history.txt/edit"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<textarea"
  end

  def test_updating
    post "/im.txt", edited_file: "new content"
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    
    get last_response['Location']
    assert_includes last_response.body, "im.txt has been updated."

    get "/im.txt"
    assert_includes last_response.body, "new content"
  end
end