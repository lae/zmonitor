Gem::Specification.new do |s|
  s.name        = 'zmonitor'
  s.version     = '0.1.0.pre'
  s.date        = '2012-04-26'
  s.summary     = "Zabbix CLI dashboard"
  s.description = "A command line interface for viewing alerts from a Zabbix instance."
  s.authors     = ["Musee Ullah"]
  s.email       = 'milkteafuzz@gmail.com'
  s.files       = ["bin/zmonitor", "lib/monitor.rb", "profiles.yml.example"]
  s.homepage    = 'https://github.com/liliff/zabbixmonitor'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'colored'
end
