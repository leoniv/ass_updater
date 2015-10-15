require "net/http"

class AssUpdater
  class HTTP
    USER_AGENT_DEFAULT = "1C+Enterprise/8.2"
    attr_accessor :user_agent,:proxy_options,:open_timeout,:read_timeout

    def initialize(proxy_options={})
      self.open_timeout = 30 #fucking 1C
      self.user_agent = USER_AGENT_DEFAULT
      self.proxy_options = {addr:nil,port:nil,user:nil,pass:nil}.merge(proxy_options)
      if block_given?
        yeld self
      end
    end

    def get(uri_str,user_name=nil,password=nil)
      response = _http(URI(uri_str)).request(_get(user_name,password,URI(uri_str)))
      _body(response,uri_str)
    end

    private

    def _body(response,uri_str)
      if response.code != "200"
        raise AssUpdater::Error.new "#{response.code} #{response.message} for `#{uri_str}'"
      end
      response.body
    end

    def _http(uri)
     h = Net::HTTP.new(uri.host,uri.port,proxy_options[:addr],proxy_options[:port],
                   proxy_options[:user],proxy_options[:pass])
     h.open_timeout = open_timeout
     h.read_timeout = read_timeout
     h
    end

    def _get(user,pass,uri)
      g = Net::HTTP::Get.new(uri.path,{"User-Agent"=>user_agent})
      if user
        g.basic_auth user,pass
      end
      g
    end

  end
end