#!/usr/bin/ruby

require 'json'
require 'net/http'
require 'net/https'

module Zabbix
  class API
    attr_accessor :api

    def initialize( api_url, api_user, api_pass )
      @api['url']	= api_url
      @api['user']	= api_user
      @api['password']	= api_pass

      # Parse the URL beforehand
      @api['uri']	= URI.parse(@api['url'])

      # Check to see if we're connecting via SSL
      @api['usessl']	= true if @api['uri'].scheme == 'https'
      
    end

    @debug = true

    # More specific error names, may add extra handling procedures later
    class ResponseCodeError < RuntimeError
    end
    class ResponseError < RuntimeError
    end
    class NotAuthorizedError < RuntimeError
    end

    def call_api(message)
      id = rand 100000

      message['id'] = id if message['id'].nil?
      message['jsonrpc'] = '2.0'
      jsonmsg = JSON.generate(msg)

      uri = URI.parse(@api_url)
      http = Net::HTTP.new(uri.host, uri.port)

      if ( uri.scheme == "https" ) then
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.add_field('Content-Type', 'application/json-rpc')
      request.body=(jsonmsg)

      begin
        puts "Sending request with body => #{request.body}" if @debug
        response = http.request(request)
      rescue ::SocketError => e
        puts "ERROR sending request: SocketError => #{e.message}" if @debug
        raise SocketError.new(e.message)
      end

      puts "Request created: #{response}" if @debug

      if response.code != "200"
        raise ResponseCodeError.new("Did not receive 200 OK from #{@api_url}, but #{response.code}")
      end

      parsed_response = JSON.parse(response.body)

      if error = parsed_response['error']
        raise ResponseError.new("Received error from Zabbix: code => #{error['code'].to_s}; message => #{error['message']}; data => #{error['data']}")
      end

      return parsed_response['result']
    end

    def check_auth()
      if @session_id == "0" and msg['method'] != "user.login"
        raise NotAuthorizedError.new("Cannot perform request without authorization. jsonmsg => #{message}")
      else
        msg['auth'] = @session_id if msg['method'] != "user.login"
      end
    end

    def login()
      login_request = {
        'method' => 'user.login',
        'params' => 
        {
          'user' => @api['user'],
          'password' => @api['pass'],
        },
        'id' => 1
      }
      result = call(login_request)
      puts "Successfully logged in as ${@api['user']}! result => #{result}" if @debug

      return result
    end
  end
end

@session_id = login()

alert_request = {
  'method' => 'alert.get',
  'params' =>
  {
    'sortfield' => 'clock',
    'limit' => '100',
    'output' => 'extend',
  }
}

last_hundred_alerts = call(alert_request)

puts last_hundred_alerts
