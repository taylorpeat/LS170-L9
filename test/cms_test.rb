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

  def create_document(name, content = " ")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { signin: "admin" } }
  end

  def test_index
    create_document "history.txt"
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "Delete"
  end

  def test_history
    create_document "history.txt", "The past is in the past"
    get "/history.txt"
    assert_equal File.read("data/history.txt"), last_response.body
  end

  def test_no_file
    get "/wrong.txt"
    assert_equal 302, last_response.status
    assert_equal "wrong.txt does not exist.", session[:error_message]
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
    get "/history.txt/edit", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
  end

  def test_editing_signed_out
    create_document "history.txt", "The past is in the past"
    get "/history.txt/edit"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:error_message]
  end

  def test_updating
    post "/im.txt", { edited_file: "new content" }, admin_session
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    
    assert_equal "im.txt has been updated.", session[:error_message]

    get "/im.txt"
    assert_includes last_response.body, "new content"
  end

  def test_updating_signed_out
    post "/im.txt"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:error_message]
  end

  def test_index_as_guest
    create_document "about.md"
    create_document "history.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "Sign In"
  end

  def test_index_signed_in
    get "/", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Index"
    assert_includes last_response.body, "New Document"
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_new
    get "/new", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
  end

  def test_new_signed_out
    get "/new"
    assert_equal 302, last_response.status
    assert_equal session[:error_message], "You must be signed in to do that."
  end

  def test_reject_new
    post "/new", { filename: "" }, admin_session
    assert_equal 302, last_response.status
    assert_equal session[:error_message], "You must enter a file name."
  end

  def test_new_completed
    post "/new", { filename: "work.txt" }, admin_session
    assert_equal 302, last_response.status
    
    get last_response["Location"]

    assert_includes last_response.body, "work.txt has been created."
    assert_includes last_response.body, "Index"

    get "/"
    assert_includes last_response.body, "work.txt"
  end

  def test_delete
    create_document "about.md"

    get "/"
    assert_includes last_response.body, "href=\"about.md"

    post "/about.md/delete", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "about.md has been deleted.", session[:error_message]

    get "/"
    refute_includes last_response.body, "href=\"about.md"
  end

  def test_delete_signed_out
    create_document "about.md"

    post "/about.md/delete"
    assert_equal 302, last_response.status
    assert_equal session[:error_message], "You must be signed in to do that."

    get "/"
    assert_includes last_response.body, "href=\"about.md"
  end


  def test_signin_page
    get "/signin"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Username:"
  end

  def test_signing_in
    post "/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "admin", session[:signin]
    assert_equal "Welcome!", session[:error_message]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_invalid_credentials
    post "/signin", username: "admin", password: "wrong"
    assert_equal 422, last_response.status
    assert_equal session[:signin], nil
    assert_includes last_response.body, "Invalid Credentials"
    assert_includes last_response.body, "Username:"
  end
end