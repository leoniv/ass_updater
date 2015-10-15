require 'test_helper'

class AssUpdaterHTTPTest < Minitest::Test
  def setup
    @http = AssUpdater::HTTP.new
  end

  def test_http
    assert_instance_of Net::HTTP, @http.send(:_http,URI("http://example.com/foo")
)
  end

  def test__get
    assert_instance_of Net::HTTP::Get, @http.send(:_get,"","",URI("http://example.com/foo")
)
  end

  def test__body
    mock_ok = Minitest::Mock.new
    mock_ok.expect(:code,"200")
    mock_ok.expect(:body,"body")
    assert_equal "body",@http.send(:_body,mock_ok,"")
    mock_err = Minitest::Mock.new
    mock_err.expect(:code, "404")
    mock_err.expect(:code, "404")
    mock_err.expect(:message, "")
    assert_raises(AssUpdater::Error){@http.send(:_body,mock_err,"")}
  end

  def get_mocked_http
    (Class.new(AssUpdater::HTTP) do
      attr_accessor :call_stack
      def initialize
        super
       self.call_stack={}
      end

      def _http(uri)
        call_stack[:_http] = [uri]
        mock = Minitest::Mock.new
        mock.expect(:request,"_http_response",[nil])
      end

      def _get(user_name,password,uri)
        call_stack[:_get] = [user_name,password,uri]
        nil
      end

      def _body(response,uri_str)
        call_stack[:_body] = [response,uri_str]
        call_stack
      end
    end).new
  end

  def test_get
    stub = {user_name:"fake_un",password:"fake_pass",uri:URI("http://example.com/foo/bar")}
    expected = {
                _http: [stub[:uri]],
                _get: [stub[:user_name],stub[:password],stub[:uri]],
                _body: ["_http_response","http://example.com/foo/bar"]
                }
    assert_equal expected,get_mocked_http.get("http://example.com/foo/bar","fake_un","fake_pass")
  end

end
