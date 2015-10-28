require 'net/http'

class AssUpdater
  # HTTP access to 1C services.
  # @note 1C servise often unavaileble and {#get} fail on timeout
  class HTTP
    # Value of useragent controled 1C web server and server may return 403 error
    USER_AGENT_DEFAULT = '1C+Enterprise/8.2'
    # (see USER_AGENT_DEFAULT)
    # @return [String]
    attr_accessor :user_agent
    # see {#initialize} param
    # @return [Hash]
    attr_accessor :proxy_options
    # see Net::HTTP#open_timeout
    # @note (see AssUpdater::HTTP)
    attr_accessor :open_timeout
    # see Net::HTTP#read_timeout
    # @note (see AssUpdater::HTTP)
    attr_accessor :read_timeout

    # @param proxy_options [Hash] options for proxy server
    def initialize(proxy_options = {})
      self.open_timeout = 30 # fucking 1C
      self.user_agent = USER_AGENT_DEFAULT
      self.proxy_options = { addr: nil,
                             port: nil,
                             user: nil,
                             pass: nil }.merge(proxy_options)
      yeld self if block_given?
    end

    # @note (see AssUpdater::HTTP)
    # @param uri_str [String]
    # @param user_name [String] user 1C sevice
    # @param password [String]
    def get(uri_str, user_name = nil, password = nil)
      response = _http(URI(uri_str)).request(_get(user_name,
                                                  password,
                                                  URI(uri_str)
                                                 )
                                            )
      _body(response, uri_str)
    end

    private

    def _body(response, uri_str)
      if response.code != '200'
        fail AssUpdater::Error,
             "#{response.code} #{response.message} for `#{uri_str}'"
      end
      response.body
    end

    def _http(uri)
      h = Net::HTTP.new(uri.host,
                        uri.port,
                        proxy_options[:addr],
                        proxy_options[:port],
                        proxy_options[:user],
                        proxy_options[:pass]
                       )
      timeouts h
    end

    def timeouts(h)
      h.open_timeout = open_timeout
      h.read_timeout = read_timeout
      h
    end

    def _get(user, pass, uri)
      g = Net::HTTP::Get.new(uri.path, 'User-Agent' => user_agent)
      g.basic_auth user, pass if user
      g
    end
  end
end
