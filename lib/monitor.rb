#!/usr/bin/ruby

require 'rubygems'
require 'colored'
require 'yaml'
require 'optparse'

require_relative 'api'
require_relative 'misc'

default_profile='zabbix'
$hide_maintenance=0

OptionParser.new do |o|
  o.banner = "usage: zmonitor [options]"
  o.on('--profile PROFILE', '-p', "Choose a different Zabbix profile. Current default is #{default_profile}") { |p| $profile = p }
  o.on('--ack MATCH', '-a', "Acknowledge current events that match a pattern MATCH. No wildcards.") { |a| $ackpattern = a.tr('^ A-Za-z0-9[]{}()|,-', '') }
  o.on('--disable-maintenance', '-m', "Filter out servers marked as being in maintenance.") { |m| $hide_maintenance = 1 }
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

def get_events() #TODO: (lines = 0)
  current_time = Time.now.to_i # to be used in getting event durations, but it really depends on the master
  triggers = $monitor.trigger.get_active(2, $hide_maintenance) # Call the API for a list of active triggers
  unacked_triggers = $monitor.trigger.get_active(2, $hide_maintenance, 1) # Call it again to get just those that are unacknowledged
  current_events = []
  triggers.each do |t|
    next if t['hosts'][0]['status'] == '1' or t['items'][0]['status'] == '1' # skip disabled items/hosts that the api call returns
#    break if current_events.length == lines and lines > 0 # don't process any more triggers if we have a limit.
#    event = $monitor.event.get_last_by_trigger(t['triggerid'])
    current_events << {
      :id => t['triggerid'].to_i,
      :time => t['lastchange'].to_i,
      :fuzzytime => fuzz(current_time - t['lastchange'].to_i),
      :severity => t['priority'].to_i,
      :hostname => t['host'],
      :description => t['description'].gsub(/ (on(| server) |to |)#{t['host']}/, '')#,
#      :eventid => event['eventid'].to_i,
#      :acknowledged => event['acknowledged'].to_i
    }
  end
  current_events.each do |e|
    s = unacked_triggers.select{ |t| t['triggerid'] == "#{e[:id]}" }
    e[:acknowledged] = s[0] ? 0 : 1
  end
  # Sort the events decreasing by severity, and then descending by duration (smaller timestamps at top)
  return current_events.sort_by { |t| [ -t[:severity], t[:time] ] }
end

if $ackpattern.nil?
  while true
    max_lines = `tput lines`.to_i - 1
    eventlist = get_events #TODO: get_events(max_lines)
    pretty_output = ['Last updated: %s' % Time.now]
    if eventlist.length != 0
      max_hostlen = eventlist.each.max { |a,b| a[:hostname].length <=> b[:hostname].length }[:hostname].length
      max_desclen = eventlist.each.max { |a,b| a[:description].length <=> b[:description].length }[:description].length
      eventlist.each do |e|
        break if pretty_output.length == max_lines
        ack = "N".red
        ack = "Y".green if e[:acknowledged] == 1
        sev_label = case e[:severity]
          when 5; 'Dstr'
          when 4; 'Hi'
          when 3; 'Wrn'
          when 2; 'Avg'
          else '???'
        end
        pretty_output << '%4s'.color_by_severity(e[:severity]) % sev_label + " %s  " % e[:fuzzytime] +
          "%-#{max_hostlen}s  " % e[:hostname] + "%-#{max_desclen}s".color_by_severity(e[:severity]) % e[:description] +
          "  Ack: %s" % ack
      end
    else
      pretty_output << ['',
        'The API call returned 0 results. Either your servers are very happy, or ZMonitor is not working correctly.',
        '', "Please check your dashboard at #{config[$profile]["url"]} to verify activity.", '',
        'ZMonitor will continue to refresh every ten seconds unless you interrupt it.']
    end
    print "\e[H\e[2J" # clear terminal screen
    puts pretty_output
    sleep(10)
  end
else
  puts 'Retrieving list of active unacknowledged triggers that match: '.bold.blue + '%s'.green % $ackpattern, ''
  filtered = []
  eventlist = get_events()
  eventlist.each do |e|
    if e[:hostname] =~ /#{$ackpattern}/ or e[:description] =~ /#{$ackpattern}/
      event = $monitor.event.get_last_by_trigger(e[:id])
      e[:eventid] = event['eventid'].to_i
      e[:acknowledged] = event['acknowledged'].to_i
      filtered << e if e[:acknowledged] == 0
    end
  end
  abort("No alerts found, so aborting".yellow) if filtered.length == 0
  filtered.each.with_index do |a,i|
    message = '%s - %s (%s)'.color_by_severity(a[:severity]) % [ a[:fuzzytime], a[:description], a[:hostname] ]
    puts "%8d >".bold % (i+1) + message
  end

  print "\n  Select > ".bold
  input = STDIN.gets.chomp()

  no_ack_msg = "Not acknowledging anything."
  raise StandardError.new('No input. #{no_ack_msg}'.green) if input == ''
  to_ack = (1..filtered.length).to_a if input == "all" # only string we'll accept
  raise StandardError.new('Invalid input. #{no_ack_msg}'.red) if to_ack.nil? and (input =~ /^([0-9 ]+)$/).nil?
  to_ack = input.split.map(&:to_i).sort if to_ack.nil? # Split our input into a sorted array of integers
  # Let's first check if a value greater than possible was given, to help prevent typos acknowledging the wrong thing
  to_ack.each { |i| raise StandardError.new('You entered a value greater than %d! Please double check. #{no_ack_msg}'.yellow % filtered.length) if i > filtered.length }

  puts  '', '           Enter an acknowledgement message below, or leave blank for the default.', ''
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
