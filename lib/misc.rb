#!/usr/bin/ruby

# Miscellaneous functions that aren't technically part of Zabbix, but are used in zabbixmon

def fuzz(dur)
  d = dur / 86400
  h = dur % 86400 / 3600
  m = dur % 86400 % 3600 / 60
  s = dur % 86400 % 3600 % 60
  if d == 0
    if h == 0
      if m == 0
        return "        %2ds" % [ s ]
      end
      return "    %2dm %2ds" % [ m, s ]
    end
    return "%2dh %2dm %2ds" % [ h, m, s ]
  end
  return "%2dd %2dh %2dm" % [ d, h, m ]
end