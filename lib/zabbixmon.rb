#!/usr/bin/ruby

require 'yaml'
require_relative 'zabbix/api'

config = YAML::load(open('profiles.yml'))

profile = "localhost"

#monitor = Zabbix::API.new(config[profile]["url"], config[profile]["user"], config[profile]["password"], true)

monitor = Zabbix::API.new(config[profile]["url"], true)
monitor.user.login(config[profile]["user"], config[profile]["password"])

apirequest = {
#  'method' => 'event.get',
#  'method' => 'alert.get',
  'method' => 'trigger.get',
#  'method' => 'template.get',
#  'method' => 'user.get',
#  'method' => 'usermacro.get',
#  'method' => 'template.get',
  'params' =>
  {
#    'time_from' => `date --date="1 hour ago" +%s`,
#    'time_till' => `date +%s`,
#    'eventids' => ["41716869", "41716855"],
    'sortfield' => 'priority,lastchange',
    'sortorder' => 'desc',
    'templated' => '0',
#    'only_true' => '1',
#    'lastChangeSince' => `date --date="30 minutes ago" +%s`,
    'filter' =>
    {
#      'host' => ["gator1157", "gator731"]
#      'priority' => ['2', '3', '4', '5'],
#      'templateid' => '157479'
#      'status' => '1'
      'value' => ['1'], #0 - OK; 1 - PROBLEM; 2 - UNKNOWN
    },
    'expandData' => 'host',
#    'select_groups' => 'extend',
#    'select_items' => 'extend',
#    'select_functions' => 'extend',
#    'triggerids' => ['445153'],
#    'select_hosts' => 'refer',
#    'select_dependencies' => 'extend',
    'expandDescription' => '1',
#    'select_triggers' => 'extend',
#    'limit' => '100',
#    'sendto' => "mullah@openfire.houston.hostgator.com",
    'min_severity' => '2',
#    'select_usrgrps' => 'extend',
#    'select_medias' => 'extend',
#    'select_mediatypes' => 'extend',
#    'select_templates' => 'extend',
#    'preservekeys' => '1',
    'output' => 'extend',
  }
}

#triggerresult = monitor.call_api(apirequest)

#puts JSON.pretty_generate(triggerresult)
