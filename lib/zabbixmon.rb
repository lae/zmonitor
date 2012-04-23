#!/usr/bin/ruby

require 'yaml'
require_relative 'zabbix/api'

profile = "localhost"
LINES = `tput lines`.to_i

def fuzz(dur)
  d = dur / 86400
  h = dur % 86400 / 3600
  m = dur % 86400 % 3600 / 60
  s = dur % 86400 % 3600 % 60
  if d == 0
    if h == 0
      if m == 0
        return "        %2ds" % [ s ]
      end
      return "    %2dm %2ds" % [ m, s ]
    end
    return "%2dh %2dm %2ds" % [ h, m, s ]
  end
  return "%2dd %2dh %2dm" % [ d, h, m ]
end

config = YAML::load(open('profiles.yml'))
monitor = Zabbix::API.new(config[profile]["url"], config[profile]["user"], config[profile]["password"])

while true
current_time = Time.now.to_i
triggers = monitor.trigger.get_active(2)

current_events = []

triggers.each do |t|
  event = monitor.event.get_last_by_trigger(t['triggerid'])
  current_events << {
    :id => t['triggerid'].to_i,
    :time => t['lastchange'].to_i,
    :fuzzytime => fuzz(current_time - t['lastchange'].to_i),
    :severity => t['priority'].to_i,
    :hostname => t['host'],
    :description => t['description'],
    :eventid => event['eventid'].to_i,
    :acknowledged => event['acknowledged'].to_i
  }
end

current_events = current_events.sort_by { |t| [ -t[:severity], -t[:time] ] }

puts "\e[H\e[2J"

puts current_time
puts current_events

sleep(10)
end
#event = monitor.event.get_last_by_trigger 13053
#monitor.event.acknowledge([event["eventid"]])
#monitor.event.acknowledge([monitor.event.get_last_by_trigger()["eventid"]])

#puts LINES