#!/usr/bin/ruby

require 'yaml'
require_relative 'zabbix/api'

config = YAML::load(open('profiles.yml'))

profile = "localhost"

monitor = Zabbix::API.new(config[profile]["url"], config[profile]["user"], config[profile]["password"])

current_time = Time.now.to_i
#triggers = monitor.trigger.get_active(2)

event = monitor.event.get_last_by_trigger 13053
#monitor.event.acknowledge([event["eventid"]])

#puts JSON.pretty_generate(triggers)
puts "separate~~"
puts JSON.pretty_generate(event)
puts "~~separate"

#puts monitor.whoami