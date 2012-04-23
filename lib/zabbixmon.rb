#!/usr/bin/ruby

require 'rubygems'
require 'colored'
require 'yaml'
require 'optparse'

require_relative 'zabbix/api'
require_relative 'misc'

default_profile='localhost'

OptionParser.new do |o|
  o.banner = "usage: zabbixmon.rb [options]"
  o.on('--profile PROFILE', '-p', "Choose a different Zabbix profile. Current default is #{default_profile}") { |p| $profile = p }
  o.on('--ack MATCH', '-a', "Acknowledge current events that match a pattern MATCH. No wildcards.") { |a| $ackpattern = a.tr('^A-Za-z0-9[]{},-', '') }
  o.on('-h', 'Show this help') { puts '',o,''; exit }
  o.parse!
end

$profile = default_profile if $profile.nil?
config = YAML::load(open('profiles.yml'))
if config[$profile].nil?
  puts 'Could not load profile '.yellow + '%s'.red % $profile + '! Trying default profile...'.yellow
  $profile = default_profile
  raise StandardError.new('Default profile is missing! Please double check your configuration.'.red) if config[$profile].nil?
end

$monitor = Zabbix::API.new(config[$profile]["url"], config[$profile]["user"], config[$profile]["password"])

def get_events()
  current_time = Time.now.to_i # to be used in getting accurate event durations
  triggers = $monitor.trigger.get_active(2) # Call the API for a list of active triggers
  current_events = []
  triggers.each do |t|
    event = $monitor.event.get_last_by_trigger(t['triggerid'])
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
  # Sort the events decreasing by severity, and then descending by duration (smaller timestamps at top)
  return current_events.sort_by { |t| [ -t[:severity], t[:time] ] }
end

if $ackpattern.nil?
  while true
    eventlist = get_events()
    puts "\e[H\e[2J"
    #lines = `tput lines`.to_i
    puts eventlist
    sleep(10)
  end
else
  puts 'Retrieving list of active triggers that match: '.bold.blue + '%s'.green % $ackpattern, ''
  acklist = []
  eventlist = get_events()
  eventlist.each { |t| acklist << t if t[:hostname] =~ /#{$ackpattern}/ or t[:description] =~ /#{$ackpattern}/ }
  acklist.each.with_index do |a,i|
    message = '%s - %s (%s)' % [ a[:fuzzytime], a[:description], a[:hostname] ]
    message = message.bold.red if a[:severity] == 5
    message = message.red if a[:severity] == 4
    message = message.yellow if a[:severity] == 3
    message = message.green if a[:severity] == 2
    puts "%8d > ".bold % i + message
  end

  print "\n  Select > ".bold
  input = STDIN.gets.chomp()


  #monitor.event.acknowledge(event["eventid"])
end