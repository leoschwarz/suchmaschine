#!/usr/bin/env ruby
############################################################################################
# Diese Datei startet, falls sie direkt ausgeführt wird, den Crawler-Client.               #
# Ansonsten werden lediglich das Common- und das Crawler-Modul geladen, ohne dass weiter   #
# etwas geschieht.                                                                         #
############################################################################################
require_relative '../lib/common/common.rb'
require_relative '../lib/crawler/crawler.rb'

if __FILE__ == $0
  Crawler::Client.new.launch
end
