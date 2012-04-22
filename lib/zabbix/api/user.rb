# api.user functions

module Zabbix
  class User < API
    attr_accessor :parent
    def initialize(parent)
      @parent = parent
      @verbose = @parent.verbose
    end
    def call_api(message)
      return @parent.call_api(message)
    end
    def login(user, password)
      request = { 'method' => 'user.login', 'params' => { 'user' => user, 'password' => password, }, 'id' => 1 }
      puts "[INFO] Logging in..." if @verbose
      result = call_api(request)
      puts "[INFO] Successfully logged in as #{user}! result => #{result}" if @verbose
      return result
    end
    def logout()
      request = { 'method' => 'user.logout' }
      puts "[INFO] Logging out..." if @verbose
      call_api(request)
      puts "[INFO] Successfully logged out." if @verbose
    end
  end
end