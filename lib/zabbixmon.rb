#!/usr/bin/ruby

require 'yaml'
require 'zabbix/api'

config = YAML::load(open('../config.yml'))

monitor = Zabbix::API.new(config["hostgator"]["url"], config["hostgator"]["user"], config["hostgator"]["password"])

monitor.login()

apirequest = {
#  'method' => 'event.get',
#  'method' => 'alert.get',
#!  'method' => 'trigger.get',
#  'method' => 'user.get',
  'method' => 'usermacro.get',
#  'method' => 'template.get',
  'params' =>
  {
#    'time_from' => `date --date="1 hour ago" +%s`,
#    'time_till' => `date +%s`,
#    'eventids' => ["41716869", "41716855"],
#!    'sortfield' => 'lastchange,priority',
#!    'sortorder' => 'desc',
#    'only_true' => '1',
#    'lastChangeSince' => `date --date="30 minutes ago" +%s`,
#!    'filter' =>
#!    {
#      'priority' => ['2', '3', '4', '5'],
#      'templateid' => '157479'
#      'status' => '1'
#!      'value' => ['1'], #0 - OK; 1 - PROBLEM; 2 - UNKNOWN
#!    },
#    'expandData' => 'host, hostid',
#    'select_groups' => 'extend',
#    'select_items' => 'extend',
#    'select_functions' => 'extend',
#    'select_hosts' => 'extend',
#    'select_dependencies' => 'extend',
#!    'expandDescription' => '1',
#    'limit' => '1',
#!    'min_severity' => '2',
#    'select_usrgrps' => 'extend',
#    'select_medias' => 'extend',
#    'select_mediatypes' => 'extend',
    'select_templates' => 'extend',
    'output' => 'extend',
  }
}

apiresult = monitor.call_api(apirequest)

puts JSON.pretty_generate(apiresult)
