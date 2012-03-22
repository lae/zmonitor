#!/usr/bin/ruby

require 'yaml'
require 'zabbix/api'

config = YAML::load(open('./config.yml'))

monitor = Zabbix::API.new(config["hostgator"]["url"], config["hostgator"]["user"], config["hostgator"]["password"])
puts "monitor.api => #{monitor.api}; monitor.debug => #{monitor.debug}"

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
    'value' => '1', #0 - OK; 1 - PROBLEM; 2 - UNKNOWN
  }
}

last_hundred_alerts = monitor.call_api(alert_request)

puts JSON.pretty_generate(last_hundred_alerts)
