#!/usr/bin/env ruby
require_relative '../lib/common/common.rb'
require_relative '../lib/database/database'

# API Dokumentation ::
# Siehe lib/database/server.rb

if __FILE__ == $0
  begin
    server = Database::Server.new
    server.start
  rescue SystemExit, Interrupt
    server.stop
  end
end
