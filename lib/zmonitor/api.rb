#!/usr/bin/ruby

require 'json'
require 'net/http'
require 'net/https'

abort("Could not load API libraries. Did you install a JSON library? (json / json_pure / json-jruby)") unless Object.const_defined?(:JSON)

# create the module/class stub so we can require the API class files properly
module Zabbix
  class API
  end
end

# load up the different API classes and methods
require 'zmonitor/api/event'
require 'zmonitor/api/trigger'
require 'zmonitor/api/user'

module Zabbix
  class API
    attr_accessor :server, :verbose, :token, :whoami

    attr_accessor :event, :trigger, :user # API classes

    def initialize( server = "http://localhost", verbose = false)
      # Parse the URL beforehand
      @server = URI.parse(server)
      @verbose = verbose

      # set up API class methods
      @user = Zabbix::User.new(self)
      @event = Zabbix::Event.new(self)
      @trigger = Zabbix::Trigger.new(self)
    end

    # More specific error names, may add extra handling procedures later
    class ResponseCodeError < StandardError
    end
    class ResponseError < StandardError
    end
    class NotAuthorisedError < StandardError
    end

    def call_api(message)
      # Finish preparing the JSON call
      message['id'] = rand 65536 if message['id'].nil?
      message['jsonrpc'] = '2.0'
      # Check if we have authorization token if we're not logging in
      if @token.nil? && message['method'] != 'user.login'
        puts "[ERROR] Authorisation Token not initialised. message => #{message}"
        raise NotAuthorisedError.new()
      else
        message['auth'] = @token if message['method'] != 'user.login'
      end

      json_message = JSON.generate(message) # Create a JSON string

      # Open TCP connection to Zabbix master
      connection = Net::HTTP.new(@server.host, @server.port)
      # Check to see if we're connecting via SSL
      if @server.scheme == 'https' then
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # Prepare POST request for sending
      request = Net::HTTP::Post.new(@server.request_uri)
      request.add_field('Content-Type', 'application/json-rpc')
      request.body = json_message

      # Send request
      begin
        puts "[INFO] Attempting to send request => #{request}" if @verbose
        response = connection.request(request)
      rescue ::SocketError => e
        puts "[ERROR] Could not complete request: SocketError => #{e.message}" if @verbose
        raise SocketError.new(e.message)
      end

      puts "[INFO] Received response: #{response}" if @verbose
      raise ResponseCodeError.new("[ERROR] Did not receive 200 OK, but HTTP code #{response.code}") if response.code != "200"

      # Check for an error, and return the parsed result if everything's fine
      parsed_response = JSON.parse(response.body)
      if error = parsed_response['error']
        raise ResponseError.new("[ERROR] Received error response: code => #{error['code'].to_s}; message => #{error['message']}; data => #{error['data']}")
      end

      return parsed_response['result']
    end
  end
end

