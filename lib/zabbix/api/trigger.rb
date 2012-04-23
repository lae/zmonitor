# api.trigger functions

module Zabbix
  class Trigger < API
    attr_accessor :parent
    def initialize(parent)
      @parent = parent
      @verbose = @parent.verbose
    end
    def call_api(message)
      return @parent.call_api(message)
    end
    def get( options = {} )
      request = { 'method' => 'trigger.get', 'params' => options }
      result = call_api(request)
      return result
    end
    def get_active( min_severity = 2 )
      request = {
        'method' => 'trigger.get',
        'params' => {
          'sortfield' => 'priority,lastchange',
          'sortorder' => 'desc',
          'templated' => '0',
          'filter' => { 'value' => ['1'] },
          'expandData' => 'host',
          'expandDescription' => '1',
          'min_severity' => min_severity.to_s,
          'output' => 'extend'
        }
      }
      return call_api(request)
    end
#    'time_from' => `date --date="1 hour ago" +%s`,
#    'time_till' => `date +%s`,
#    'eventids' => ["41716869", "41716855"],

#    'only_true' => '1',
#    'lastChangeSince' => `date --date="30 minutes ago" +%s`,

#      'host' => ["gator1157", "gator731"]
#      'priority' => ['2', '3', '4', '5'],
#      'templateid' => '157479'
#      'status' => '1'
#    'select_groups' => 'extend',
#    'select_items' => 'extend',
#    'select_functions' => 'extend',
#    'triggerids' => ['445153'],
#    'select_hosts' => 'refer',
#    'select_dependencies' => 'extend',
#    'select_triggers' => 'extend',
#    'limit' => '100',
#    'sendto' => "mullah@openfire.houston.hostgator.com",
#    'select_usrgrps' => 'extend',
#    'select_medias' => 'extend',
#    'select_mediatypes' => 'extend',
#    'select_templates' => 'extend',
#    'preservekeys' => '1',
  end
end