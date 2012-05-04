Gem::Specification.new do |s|
  s.name        = 'zmonitor'
  s.version     = '1.0.6'
  s.date        = '2012-05-03'
  s.summary     = "Zabbix CLI dashboard"
  s.description = "A command line interface for viewing alerts from a Zabbix instance."
  s.authors     = ["Musee Ullah"]
  s.email       = 'milkteafuzz@gmail.com'
  s.files       = Dir['lib/**/*.rb']
  s.executables = ["zmonitor"]
  s.homepage    = 'https://github.com/liliff/zonitor'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'colored'
end