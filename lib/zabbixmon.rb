#!/usr/bin/ruby

require 'yaml'
require_relative 'zabbix/api'

config = YAML::load(open('profiles.yml'))

profile = "localhost"

monitor = Zabbix::API.new(config[profile]["url"])
monitor.authtoken = monitor.user.login(config[profile]["user"], config[profile]["password"])

triggers = monitor.trigger.get_active(2)

puts JSON.pretty_generate(triggers)
