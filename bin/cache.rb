require 'socket'
require './config/config.rb'
require './lib/cache/cache.rb'

# TODO: Mehrere Einträge in eine Datei schreiben und stark frequentierte Datensätze im RAM lagern.

# API Dokumentation :: 
# 
# GET KEY
# SET KEY VALUE
#
# Antworten ::
# STRING VALUE
# NULL

# fürs Debuggen
Thread.abort_on_exception = true

load_configuration(Cache, "cache.yml")
module Cache
  def self.run
    server = TCPServer.new("127.0.0.1", 2052)
    
    loop do
      client = server.accept
      message = client.recv(10000000)
      parts = message.split(" ", 3)
  
      unless parts[0].nil?
        action = parts[0].upcase
      else
        action = nil
      end
  
      if action == "GET"
        key = parts[1]
        value = MemoryCache.get(key)
        response = value.nil? ? "NULL" : "STRING "+value
    
        client.write response
        client.close
      elsif action == "SET"
        key = parts[1]
        value = parts[2]
        MemoryCache.set(key, value)
    
        client.write "NULL"
        client.close
      elsif not action.nil?
        puts "Unbekannte Aktion: #{action}"
      end
    end
  end
end

if __FILE__ == $0
  Cache.run
end
