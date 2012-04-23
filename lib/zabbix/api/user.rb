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
    # General user.get
    def get( options = {} )
      request = { 'method' => 'user.get', 'params' => options }
      return call_api(request)
    end
    # Get first and last name of currently logged in user
    def get_fullname()
      request = { 'method' => 'user.get', 'output' => 'extend' }
      whoami = self.get({ 'output' => 'extend' })
      return whoami[0]["name"] + " " + whoami[0]["surname"]
    end
    # Perform a login procedure
    def login(user, password)
      request = { 'method' => 'user.login', 'params' => { 'user' => user, 'password' => password, }, 'id' => 1 }
      puts "[INFO] Logging in..." if @verbose
      result = call_api(request)
      puts "[INFO] Successfully logged in as #{user}! result => #{result}" if @verbose
      return result
    end
    # Perform a logout
    def logout()
      request = { 'method' => 'user.logout' }
      puts "[INFO] Logging out..." if @verbose
      call_api(request)
      puts "[INFO] Successfully logged out." if @verbose
    end
  end
end