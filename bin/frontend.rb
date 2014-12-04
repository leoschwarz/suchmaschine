#!/usr/bin/env ruby
############################################################################################
# Diese Datei startet, falls sie direkt ausgeführt wird, den Webserver.                    #
# Ansonsten werden lediglich das Common- und das Frontend-Modul geladen, ohne dass weiter  #
# etwas geschieht.                                                                         #
############################################################################################
require_relative '../lib/common/common.rb'
require_relative '../lib/frontend/frontend.rb'

if __FILE__ == $0
  Frontend::WebServer.run!
end
