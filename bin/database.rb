#!/usr/bin/env ruby
############################################################################################
# Diese Datei startet, falls sie direkt ausgeführt wird, den Datenbank-Server.             #
# Ansonsten werden lediglich das Common- und das Datenbank-Modul geladen, ohne dass weiter #
# etwas geschieht.                                                                         #
############################################################################################
require_relative '../lib/common/common.rb'
require_relative '../lib/database/database'

if __FILE__ == $0
  begin
    server = Database::Server.new
    server.start
  rescue SystemExit, Interrupt
    server.stop
  end
end
