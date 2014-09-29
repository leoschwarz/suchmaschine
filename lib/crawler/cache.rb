require 'socket'

module Crawler
  class Cache
    def self.run(query)
      begin
        connection = TCPSocket.new("127.0.0.1", 2052)
        connection.write(query)
        response   = connection.recv(10000000)
        connection.close
        
        parts = response.split(" ", 2)
        if parts[0] == "STRING"
          return parts[1]
        elsif parts[0] == "NULL"
          return nil
        else
          puts "Fehler: Unbekannter Datentyp für CacheItem: #{parts[0]}"
          return nil
        end
      rescue Exception
        # TODO
        return nil
      end
    end
    
    def self.get(key)
      run "GET #{key}"
    end
    
    def self.set(key, value)
      run "SET #{key} #{value}"
    end
  end
end