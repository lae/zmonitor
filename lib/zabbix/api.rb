#!/usr/bin/ruby

require 'json'
require 'net/http'
require 'net/https'
require 'yaml'

module Zabbix
  class API
    attr_accessor :api, :debug, :authtoken

    def initialize( api_url, api_user, api_password, debug = false )
      @api = Hash.new()
      @api['url']	= api_url
      @api['user']	= api_user
      @api['password']	= api_password

      @debug = debug

      # Parse the URL beforehand
      @api['uri']	= URI.parse(@api['url'])

      # Check to see if we're connecting via SSL
      @api['usessl']	= true if @api['uri'].scheme == 'https'
    end

    # More specific error names, may add extra handling procedures later
    class ResponseCodeError < RuntimeError
    end
    class ResponseError < RuntimeError
    end
    class NotAuthorisedError < RuntimeError
    end

    def call_api(message)
      # Finish preparing the JSON call
      message['id'] = rand 100000 if message['id'].nil?
      message['jsonrpc'] = '2.0'

      # Check if we have authorization token
      if @authtoken.nil? && message['method'] != 'user.login'
        raise NotAuthorisedError.new("[ERROR] Authorisation Token not initialised. message => #{message}")
      else
        message['auth'] = @authtoken if message['method'] != 'user.login'
      end

      json_message = JSON.generate(message)

      # Open TCP connection to Zabbix master
      connection = Net::HTTP.new(@api['uri'].host, @api['uri'].port)
      if @api['usessl'] then
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # Prepare POST request for sending
      request = Net::HTTP::Post.new(@api['uri'].request_uri)
      request.add_field('Content-Type', 'application/json-rpc')
      request.body = json_message

      # Send request
      begin
        puts "[INFO] Attempting to send request => #{request}" if @debug
        response = connection.request(request)
      rescue ::SocketError => e
        puts "[ERROR] Could not complete request: SocketError => #{e.message}" if @debug
        raise SocketError.new(e.message)
      end

      puts "[INFO] Received response: #{response}" if @debug
      raise ResponseCodeError.new("[ERROR] Did not receive 200 OK, but HTTP code #{response.code}") if response.code != "200"

      parsed_response = JSON.parse(response.body)
      if error = parsed_response['error']
        raise ResponseError.new("[ERROR] Received error response: code => #{error['code'].to_s}; message => #{error['message']}; data => #{error['data']}")
      end

      return parsed_response['result']
    end

    def login()
      login_request = {
        'method' => 'user.login',
        'params' =>
        {
          'user' => @api['user'],
          'password' => @api['password'],
        },
        'id' => 1
      }
      puts "[INFO] Logging in..." if @debug
      @authtoken = self.call_api(login_request)
      puts "[INFO] Successfully logged in as #{@api['user']}! @authtoken => #{@authtoken}" if @debug
    end
  end
end
