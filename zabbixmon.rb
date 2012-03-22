#!/usr/bin/ruby

require 'json'
require 'yaml'
require 'net/http'
require 'net/https'

config = YAML::load(open('./config.yml'))

@api_url = config["zabbix"]["url"]
@api_login = config["zabbix"]["login"]
@api_password = config["zabbix"]["password"]

@debug = true

class ResponseCodeError < RuntimeError
end

class ResponseError < RuntimeError
end

class NotAuthorizedError < RuntimeError
end

def call(msg)
  id = rand 100000

  msg['id'] = id if msg['id'].nil?
  msg['jsonrpc'] = '2.0'

  if @session_id.nil? and msg['method'] != "user.login"
    raise NotAuthorizedError.new("Cannot perform request without authorization. jsonmsg => #{msg}")
  else
    msg['auth'] = @session_id if msg['method'] != "user.login"
  end

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

def login()
  login_request = {
    'auth'   => 'nil',
    'method' => 'user.login',
    'params' => 
    {
      'user' => @api_login,
      'password' => @api_password,
    },
    'id' => 1
  }
  session_id = call(login_request)
  puts "Successfully logged in! session_id => #{session_id}" if @debug

  return session_id
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
