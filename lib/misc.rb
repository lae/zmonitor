#!/usr/bin/ruby

# Miscellaneous functions that aren't technically part of Zabbix, but are used in zabbixmon

def fuzz(t)
  t = 0 if t < 0 # we don't need negative fuzzy times.
  d = t / 86400
  h = t % 86400 / 3600
  m = t % 3600  / 60
  s = t % 60
  fuzzy = ['d', 'h', 'm', 's'].map do |unit|
    amt = eval(unit)
    "%3d#{unit}" % amt
  end.join
  return "#{fuzzy}"[4..-1] if d == 0
  return "#{fuzzy}"[0..-5]
end

class String
  def color_by_severity( level = 0 )
    case level
      when 5; self.bold.red
      when 4; self.red
      when 3; self.yellow
      when 2; self.green
      else self
    end
  end
end