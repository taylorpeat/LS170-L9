ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require 'fileutils'
require 'pry'

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
    create_document "history.txt", "The past is in the past"
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
    create_document "about.md", "<em>"
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html", last_response["Content-Type"]
    assert_includes last_response.body, "<em>"
  end

  def test_editing
    create_document "history.txt", "The past is in the past"
    get "/history.txt/edit"
    assert_equal 200, last_response.status
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

  def create_document(name, content = " ")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    create_document "about.md"
    create_document "history.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "history.txt"
  end
end