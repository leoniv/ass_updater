require 'test_helper'

class AssUpdaterHTTPTest < Minitest::Test
  def setup
    @http = AssUpdater::HTTP.new
  end

  def test_get_public_data
    skip
    assert_raises(AssUpdater::Error){ @http.get("http://example.org/foo/bar") }
  end

  def test_get_locked_data
    skip
    user = "foo"
    pass = "bar"
    assert_raises(AssUpdater::Error){ @http.get("http://example.com/foo/bar",user,pass)}
  end
end
