# api.event functions

module Zabbix
  class Event < API
    attr_accessor :parent
    def initialize(parent)
      @parent = parent
      @verbose = @parent.verbose
    end
    def call_api(message)
      return @parent.call_api(message)
    end
    def get( options = {} )
      request = { 'method' => 'event.get', 'params' => options }
      return call_api(request)
    end
    def get_last_by_trigger( triggerid = '' )
      request = {
        'method' => 'event.get',
        'params' =>
        {
          'triggerids' => triggerid.to_s,
          'sortfield' => 'clock',
          'sortorder' => 'DESC',
          'limit' => '1',
          'output' => 'extend'
        }
      }
      return call_api(request)
    end
    def acknowledge( events = [], message = "#{@parent.whoami} is working on this." )
      request = { 'method' => 'event.acknowledge', 'params' => { 'eventids' => events, 'message' => message } }
      call_api(request)
    end
  end
end