#!/usr/bin/ruby

require 'yaml'
require_relative 'zabbix/api'

profile = "localhost"
LINES = `tput lines`.to_i

config = YAML::load(open('profiles.yml'))
monitor = Zabbix::API.new(config[profile]["url"], config[profile]["user"], config[profile]["password"])
current_time = Time.now.to_i
triggers = monitor.trigger.get_active(2)

currentevents = []

triggers.each do |t|
  id = t['triggerid']
  event = monitor.event.get_last_by_trigger(t['triggerid'])
  currentevents << {
    :id => id,
    :time => t['lastchange'],
    :severity => t['priority'],
    :hostname => t['host'],
    :description => t['description'],
    :eventid => event['eventid'],
    :acknowledged => event['acknowledged']
  }
end

puts currentevents
#event = monitor.event.get_last_by_trigger 13053
#monitor.event.acknowledge([event["eventid"]])
#monitor.event.acknowledge([monitor.event.get_last_by_trigger()["eventid"]])

#puts LINES