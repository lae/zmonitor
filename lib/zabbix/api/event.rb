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
    def get()
#      return result
    end
  end
end