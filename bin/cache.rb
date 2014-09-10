require 'socket'

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


server = TCPServer.new("127.0.0.1", 2052)

def cache_path(key)
  # TODO: Verbessern
  "cache/keyval/#{key}"
end

loop do
  Thread.start(server.accept) do |client|
    message = client.recv(10000000)
    parts = message.split(" ", 3)
    
    unless parts[0].nil?
      action = parts[0].upcase
    else
      action = nil
    end
    
    if action == "GET"
      key = parts[1]
      
      file_path = cache_path(key)
      if File.exists? file_path
        client.write "STRING " + File.read(file_path)
        client.close
      else
        client.write "NULL"
        client.close
      end
    elsif action == "SET"
      key = parts[1]
      value = parts[2]
      
      file = File.open(cache_path(key), "w")
      file.write(value)
      file.close
      client.write "NULL"
      client.close
    elsif not action.nil?
      puts "Unbekannte Aktion: #{action}"
    end
  end
end
