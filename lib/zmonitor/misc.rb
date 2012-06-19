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
  return "#{fuzzy}"[8..-1] if h == 0
  return "#{fuzzy}"[4..-5] if d == 0
  return "#{fuzzy}"[0..-9]
end

class String
  def color_by_severity( level = 0 )
    case level
      when 5; self.bold.red
      when 4; self.yellow
      when 3; self.green
      when 2; self.cyan
      when 1; self.bold.white
      else self
    end
  end
end
