#!/bin/bash

while true
  LINES=$(tput lines)
  do ./lib/zabbixmon.rb |
  grep -oP "((?<=\"priority\": \").(?=\")|(?<=\"lastchange\": \").*(?=\")|(?<=\"host\": \").*(?=\")|(?<=\"description\": \").*(?=\"))" |
#  grep -oP "((?<=\"priority\": \").(?=\")|(?<=\"lastchange\": \").*(?=\")|(?<=\"description\": \").*(?=\"))" |
  grep -vP "(Zabbix.*(hakaze|bra10|new-joyce|HOST.win)|CPU Idle|pva(node|master)|(Too many|POP3|IMAP).*vps6(03|02|14))" |
  grep -vP "(IOWait high on (amigo|camaro|cadillac)|Conroe load is too high on magnum|Processor load is too high on retona)" |
#  if [ ! -z "$2" ]; then ignored=$(grep -cP "gator($(seq $1 $2 | tr '\n' '|' | sed 's/.$//'))"); grep -vP "gator($(seq $1 $2 | tr '\n' '|' | sed 's/.$//'))";else grep ".";fi |
  grep -B3 -P "[a-z]+ [a-z]+" |
  grep -v "\-\-" |
  paste -d ' ' - - - - |
  sort -k 1,1rn -k 2n  > zabbixlog
  if [ ! -z "$3" ]; then
    ignored=$(grep -cP "($3|gator($(seq $1 $2 | tr '\n' '|' | sed 's/.$//')))" zabbixlog)
    grep -vP "($3|gator($(seq $1 $2 | tr '\n' '|' | sed 's/.$//')))" zabbixlog > zabbixlog2
    mv zabbixlog zabbixlog-withoutignoredservers
    mv zabbixlog2 zabbixlog
  elif [ ! -z "$2" ]; then
    ignored=$(grep -cP "gator($(seq $1 $2 | tr '\n' '|' | sed 's/.$//'))" zabbixlog)
    grep -vP "gator($(seq $1 $2 | tr '\n' '|' | sed 's/.$//'))" zabbixlog > zabbixlog2
    mv zabbixlog zabbixlog-withoutignoredservers
    mv zabbixlog2 zabbixlog
  elif [ ! -z "$1" ]; then
    ignored=$(grep -cP "$1" zabbixlog)
    grep -vP "$1" zabbixlog > zabbixlog2
    mv zabbixlog zabbixlog-withoutignoredservers
    mv zabbixlog2 zabbixlog
  fi

  loglines=$(
    head -n $(( $LINES - 2)) zabbixlog |
    wc -l |
    awk '{print $1}'
  )
  head -n $loglines zabbixlog |
  while read line
    do epochdate=$(echo $line | awk '{print $2}')
#    date=$(echo "date -d @$epochdate" | sh)
#    echo $line | sed "s/$epochdate/$date/"
    S=$(echo $(date +%s) - $epochdate | bc)
    ((d=S/86400))
    ((h=S%86400/3600))
    ((m=S%3600/60))
    ((s=S%60))
    if [ $d -eq 0 ];then
      duration=$(printf "%2dh %2dm %2ds\t  " $h $m $s)
    else
      duration=$(printf "%dd %2dh %2dm\t  " $d $h $m)
    fi
    echo $line | sed "s/$epochdate/$duration/"
  done > zabbixlogmod

# use below to comment out maintenance servers
#    if [ "$1" -eq "$1" ]; then
#      grep -vP "gator($(seq $1 $2 | tr '\n' '|'))" zabbixlogmod | tee zabbixlogmod
#    else
#      echo "Invalid arguments passed. Ignoring. (Make sure you're using two numbers.)"
#    fi
#  fi

  date | tr -d '\n'
  echo " Ignored Alerts: $ignored"
  sed -i "s/^5/[Disaster]/g" zabbixlogmod
  sed -i "s/^4/[High]    /g" zabbixlogmod
  sed -i "s/^3/[Warning] /g" zabbixlogmod
  sed -i "s/^2/[Average] /g" zabbixlogmod
#  sed -i -r "s/([ 1-6][0-9])s /\1s \t\t/g" zabbixlogmod
#  sed -i -r "s/([- 1-6][0-9])s /\1s \t\t/g" zabbixlogmod
  sed -i -r "s/(\w+\.\w+\.\w+(\.\w+)?) ([A-Z0-9])/\1\t\t\3/g" zabbixlogmod
  cat zabbixlogmod
  for i in $(seq 3 $(($LINES - $loglines)));do echo;done
  sleep 5
done
