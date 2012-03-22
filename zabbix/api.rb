#!/usr/bin/ruby

require 'json'
require 'net/http'
require 'net/https'
require 'yaml'

module Zabbix
  class API
#    attr_accessor :api

    def initialize( api_url, api_user, api_pass )
      @api = Hash.new()
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
      # Finish preparing the JSON call
      message['id'] = rand 100000 if message['id'].nil?
      message['jsonrpc'] = '2.0'
      message['auth'] = check_auth(message)
      json_message = JSON.generate(message)

      # Open TCP connection to Zabbix master
      connection = Net::HTTP.new(@api['uri'].host, @api['uri'].port)
      if @api['usessl'] then
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # Build POST request for sending
      request = Net::HTTP::Post.new(@api['uri'].request_uri)
      request.add_field('Content-Type', 'application/json-rpc')
      request.body = json_message

      begin
        puts "Sending request with body => #{request.body}" if @debug
        response = connection.request(request)
      rescue ::SocketError => e
        puts "[ERROR] Could not complete request: SocketError => #{e.message}" if @debug
        raise SocketError.new(e.message)
      end

      puts "Request created: #{response}" if @debug

      raise ResponseCodeError.new("[ERROR] Did not receive 200 OK, but #{response.code}") if response.code != "200"

      parsed_response = JSON.parse(response.body)

      raise ResponseError.new("[ERROR] Received invalid response: code => #{error['code'].to_s}; message => #{error['message']}; data => #{error['data']}") if error = parsed_response['error']

      return parsed_response['result']
    end

    def check_auth(message)
      if @session_id == "0" and message['method'] != "user.login"
        raise NotAuthorizedError.new("[WARNING] Cannot perform request without authorization. jsonmsg => #{message}")
      else
        return @session_id if message['method'] != "user.login"
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
      result = call_api(login_request)
      puts "[INFO] Successfully logged in as ${@api['user']}! result => #{result}" if @debug

      return result
    end
  end
end

# Testing

config = YAML::load(open('../config.yml'))
monitor = Zabbix::API.new(config["zabbix"]["url"], config["zabbix"]["username"], config["zabbix"]["password"])
monitor.login

alert_request = {
  'method' => 'event.get',
  'params' =>
  {
    'time_from' => `date --date="1 hour ago" +%s`,
    'time_till' => `date +%s`,
    'sortfield' => 'clock',
    'sortorder' => 'desc',
#    'limit' => '100',
    'output' => 'extend',
  }
}

last_hundred_alerts = monitor.call_api(alert_request)

puts JSON.pretty_generate(last_hundred_alerts)
