#!/usr/bin/ruby

require 'colored'

require 'zmonitor/api'
require 'zmonitor/misc'

module Zabbix
  class Monitor
    attr_accessor :api, :hide_maintenance

    class EmptyFileError < StandardError
      attr_reader :message
      def initialize(reason, file)
        @message = reason
        puts "[INFO] Deleting #{file}"
        File.delete(file)
      end
    end
    def initialize()
      @hide_maintenance = 0
      uri = self.check_uri()
      @api = Zabbix::API.new(uri)
      @api.token = self.check_login
      @api.whoami = @api.user.get_fullname()
    end
    def check_uri()
      uri_path = File.expand_path("~/.zmonitor-server")
      if File.exists?(uri_path)
        uri = File.open(uri_path).read()
      else
        puts "Where is your Zabbix located? (please include https/http - for example, https://localhost)"
        uri = "#{STDIN.gets.chomp()}/api_jsonrpc.php"
        f = File.new(uri_path, "w+")
        f.write(uri)
        f.close
      end
      puts "Okay, using #{uri}."
      raise EmptyFileError.new('URI is empty for some reason', uri_path) if uri == '' || uri.nil?
      return uri
    end
    def check_login()
      token_path = File.expand_path("~/.zmonitor-token")
      if File.exists?(token_path)
        token = File.open(token_path).read()
      else
        print "Please enter your Zabbix username: "
        user = STDIN.gets.chomp()
        print "Please enter your Zabbix password: "
        begin
          system "stty -echo"
          password = gets.chomp
        ensure
          system "stty echo"
          puts
        end
        token = @api.user.login(user, password).chomp
        f = File.new(token_path, "w+")
        f.write(token)
        f.close
      end
      raise EmptyFileError.new("Token is empty!", token_path) if token == '' || token.nil?
      return token
    end
    def get_events()
      current_time = Time.now.to_i # to be used in getting event durations, but it really depends on the master
      triggers = @api.trigger.get_active(2, @hide_maintenance) # Call the API for a list of active triggers
      unacked_triggers = @api.trigger.get_active(2, @hide_maintenance, 1) # Call it again to get just those that are unacknowledged
      current_events = []
      triggers.each do |t|
        next if t['hosts'][0]['status'] == '1' or t['items'][0]['status'] == '1' # skip disabled items/hosts that the api call returns
        current_events << {
          :id => t['triggerid'].to_i,
          :time => t['lastchange'].to_i,
          :fuzzytime => fuzz(current_time - t['lastchange'].to_i),
          :severity => t['priority'].to_i,
          :hostname => t['host'],
          :description => t['description'].gsub(/ (on(| server) |to |)#{t['host']}/, '')#,
        }
      end
      current_events.each do |e|
        s = unacked_triggers.select{ |t| t['triggerid'] == "#{e[:id]}" }
        e[:acknowledged] = s[0] ? 0 : 1
      end
      # Sort the events decreasing by severity, and then descending by duration (smaller timestamps at top)
      return current_events.sort_by { |t| [ -t[:severity], t[:time] ] }
    end
    def get_dashboard(format = '')
      max_lines = `tput lines`.to_i - 1
      cols = `tput cols`.to_i
      eventlist = self.get_events() #TODO: get_events(max_lines)
      pretty_output = ["%-#{cols/2}s".cyan_on_blue % "Last updated: #{Time.now}" + "%#{cols/2}s".cyan_on_blue % " Zmonitor Dashboard"]
      if eventlist.length != 0
        max_hostlen = eventlist.each.max { |a,b| a[:hostname].length <=> b[:hostname].length }[:hostname].length
        max_desclen = eventlist.each.max { |a,b| a[:description].length <=> b[:description].length }[:description].length
        eventlist.each do |e|
          break if pretty_output.length == max_lines and format != 'full'
          ack = "N".red
          ack = "Y".green if e[:acknowledged] == 1
          pretty_output << "%s " % e[:fuzzytime] + "%-#{max_hostlen}s " % e[:hostname] +
          "%-#{max_desclen}s".color_by_severity(e[:severity]) % e[:description] + " %s" % ack
        end
      else
        pretty_output << ['',
          'The API calls returned 0 results. Either your servers are very happy, or ZMonitor is not working correctly.',
          '', "Please check your dashboard at #{@api.server.to_s.gsub(/\/api_jsonrpc.php/, '')} to verify activity.", '',
          'ZMonitor will continue to refresh every ten seconds unless you interrupt it.']
      end
      print "\e[H\e[2J" if format != 'full' # clear terminal screen
      puts pretty_output
    end
    def acknowledge(pattern = '')
      puts 'Retrieving list of active unacknowledged triggers that match: '.bold.blue + '%s'.green % pattern, ''
      filtered = []
      eventlist = self.get_events()
      eventlist.each do |e|
        if e[:hostname] =~ /#{pattern}/ or e[:description] =~ /#{pattern}/
          event = @api.event.get_last_by_trigger(e[:id])
          e[:eventid] = event['eventid'].to_i
          e[:acknowledged] = event['acknowledged'].to_i
          filtered << e if e[:acknowledged] == 0
        end
      end
      abort("No alerts found, so aborting".yellow) if filtered.length == 0
      filtered.each.with_index do |a,i|
        message = '%s - %s (%s)'.color_by_severity(a[:severity]) % [ a[:fuzzytime], a[:description], a[:hostname] ]
        puts "%4d >".bold % (i+1) + message
      end

      puts '', '       Selection - enter "all", or a set of numbers listed above separated by spaces.'
      print ' Sel > '.bold
      input = STDIN.gets.chomp()

      no_ack_msg = "Not acknowledging anything."
      raise StandardError.new("No input. #{no_ack_msg}".green) if input == ''
      to_ack = (1..filtered.length).to_a if input == "all" # only string we'll accept
      raise StandardError.new("Invalid input. #{no_ack_msg}".red) if to_ack.nil? and (input =~ /^([0-9 ]+)$/).nil?
      to_ack = input.split.map(&:to_i).sort if to_ack.nil? # Split our input into a sorted array of integers
      # Let's first check if a value greater than possible was given, to help prevent typos acknowledging the wrong thing
      to_ack.each { |i| raise StandardError.new("You entered a value greater than %d! Please double check. #{no_ack_msg}".yellow % filtered.length) if i > filtered.length }

      puts  '', '       Message   - enter an acknowledgement message below, or leave blank for the default.'
      print ' Msg > '.bold
      message = STDIN.gets.chomp()
      puts

      # Finally! Acknowledge EVERYTHING
      to_ack.each do |a|
        puts 'Acknowledging: '.green + '%s (%s)' % [ filtered[a-1][:description], filtered[a-1][:hostname] ]
        if message == ''
          @api.event.acknowledge(filtered[a-1][:eventid])
        else
          @api.event.acknowledge(filtered[a-1][:eventid], message)
        end
      end
    end
    # Save a time offset between the local computer and the Zabbix master
    def calibrate()
      #
    end
  end
end
