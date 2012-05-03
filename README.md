# zmonitor

A command line interface for viewing alerts from a Zabbix instance.

This is a quick mashup to get on the ground running, but I plan on doing quite
a bit more work than what's probably currently here.

## Requirements
Rubygems: json (json_pure is fine), colored

## Usage
    zmonitor [options]
        -p, --profile PROFILE            Choose a different Zabbix profile. Current default is zabbix
        -a, --ack MATCH                  Acknowledge current events that match a pattern MATCH. No wildcards.
        -m, --disable-maintenance        Filter out servers marked as being in maintenance.
        -h                               Show this help

## Setting Up

Install any missing gems, and ensure your environment is set up correctly.

    gem install json colored

Edit profiles.yml with your correct login credentials (copy from profiles.yml.example).

In the directory you have your profiles.yml located in, run zmonitor:

    cd zabbixmonitor
    ruby bin/zmonitor

You can just copy bin/* and lib/* into your PATH, and "zmonitor" can be run by itself. You'll need to copy profiles.yml, too.

Rubygem creation to facilitate this is a work in progress.
