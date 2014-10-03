require 'socket'

module Common
  class FastClient
    def initialize(host, port)
      @host = host
      @port = port
    end
    
    # Führt die Anfrage aus und gibt das Resultat als String zurück.
    def request(req)
      socket = TCPSocket.new(@host, @port)
      socket.puts(req)
      response = socket.gets.strip
      socket.close
      response
    end
  end
end