#!/usr/bin/ruby

require 'rubygems'
require 'colored'
require 'yaml'
require 'optparse'

require_relative 'api'
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
  triggers.each.with_index do |t,i|
    next if t['hosts'][0]['status'] == '1' or t['items'][0]['status'] == '1' # skip disabled items/hosts that the api call returns
#    event = $monitor.event.get_last_by_trigger(t['triggerid'])
    current_events << {
      :id => t['triggerid'].to_i,
      :time => t['lastchange'].to_i,
      :fuzzytime => fuzz(current_time - t['lastchange'].to_i),
      :severity => t['priority'].to_i,
      :hostname => t['host'],
      :description => t['description']#,
#      :eventid => event['eventid'].to_i,
#      :acknowledged => event['acknowledged'].to_i
    }
    unless $ackpattern.nil?
      event = $monitor.event.get_last_by_trigger(t['triggerid'])
      current_events[i][:eventid] = event['eventid'].to_i
      current_events[i][:acknowledged] = event['acknowledged'].to_i
    end
  end
  # Sort the events decreasing by severity, and then descending by duration (smaller timestamps at top)
  return current_events.sort_by { |t| [ -t[:severity], t[:time] ] }
end

if $ackpattern.nil?
  while true
    max_lines = `tput lines`.to_i - 1
    eventlist = get_events()
    pretty_output = ['%s' % Time.now]
    max_host_length = eventlist.each.max { |a,b| a[:hostname].length <=> b[:hostname].length }[:hostname].length
    eventlist.each do |e|
      desc = e[:description]
      case e[:severity]
      when 5
        sev = 'Disaster'.bold.red
        desc = desc.bold.red
      when 4
        sev = 'High'.red
        desc = desc.red
      when 3
        sev = 'Warning'.yellow
        desc = desc.yellow
      when 2
        sev = 'Average'.green
        desc = desc.green
      else sev = 'Unknown'
      end
      e[:severity] = '[%17s]' % sev
      e[:description] = desc
    end
    max_desc_length = eventlist.each.max { |a,b| a[:description].length <=> b[:description].length }[:description].length
    eventlist.each do |e|
      ack = "N/A"
 #     ack = "Yes" if e[:acknowledged] == 1
      pretty_output << "%s %s\t%-#{max_host_length}s\t%-#{max_desc_length}s\tAck: %s" % [ e[:severity], e[:fuzzytime], e[:hostname], e[:description], ack ] if pretty_output.length < max_lines
    end
    print "\e[H\e[2J" # clear terminal screen
    puts pretty_output
    sleep(10)
  end
else
  puts 'Retrieving list of active triggers that match: '.bold.blue + '%s'.green % $ackpattern, ''
  filtered = []
  eventlist = get_events()
  eventlist.each { |e| filtered << e if e[:hostname] =~ /#{$ackpattern}/ or e[:description] =~ /#{$ackpattern}/ and e[:acknowledged] == 0 }
  filtered.each.with_index do |a,i|
    message = '%s - %s (%s)' % [ a[:fuzzytime], a[:description], a[:hostname] ]
    message = message.bold.red if a[:severity] == 5
    message = message.red if a[:severity] == 4
    message = message.yellow if a[:severity] == 3
    message = message.green if a[:severity] == 2
    puts "%8d > ".bold % (i+1) + message
  end

  print "\n  Select > ".bold
  input = STDIN.gets.chomp()

  raise StandardError.new('No input. Not acknowledging anything.'.green) if input == ''
  to_ack = (1..filtered.length).to_a if input == "all" # only string we'll accept
  raise StandardError.new('Invalid input. Not acknowledging anything.'.red) if to_ack.nil? and (input =~ /^([0-9 ]+)$/).nil?
  to_ack = input.split.map(&:to_i).sort if to_ack.nil? # Split our input into a sorted array of integers
  # Let's first check if a value greater than possible was given, to help prevent typos acknowledging the wrong thing
  to_ack.each { |i| raise StandardError.new('There isn\'t anything to acknowledge above %d!'.yellow % filtered.length) if i > filtered.length }

  print " Message > ".bold
  message = STDIN.gets.chomp()
  puts

  # Finally! Acknowledge EVERYTHING
  to_ack.each do |a|
    puts 'Acknowledging: '.green + '%s (%s)' % [ filtered[a-1][:description], filtered[a-1][:hostname] ]
    if message == ''
      $monitor.event.acknowledge(filtered[a-1][:eventid])
    else
      $monitor.event.acknowledge(filtered[a-1][:eventid], message)
    end
  end
end
