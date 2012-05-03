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
    # General trigger.get
    def get( options = {} )
      request = { 'method' => 'trigger.get', 'params' => options }
      return call_api(request)
    end
    # Get a hash of all unresolved problem triggers
    def get_active( min_severity = 2, maint = 0, lastack = 0 )
      request = {
        'method' => 'trigger.get',
        'params' => {
          'sortfield' => 'priority,lastchange',
          'sortorder' => 'desc',
          'templated' => '0',
          'filter' => { 'value' => '1', 'status' => '0' },
          'expandData' => 'host',
          'expandDescription' => '1',
          'min_severity' => min_severity.to_s,
          'select_hosts' => 'extend',
          'select_items' => 'extend',
          'output' => 'extend'
        }
      }
      request['params']['maintenance'] = 0 if maint == 1
      request['params']['withLastEventUnacknowledged'] = 1 if lastack == 1
      return call_api(request)
    end
  end
end
