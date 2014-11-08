require 'socket'

module Common
  class FastClient
    def initialize(host, port)
      @host = host
      @port = port
    end

    # Führt die Anfrage aus und gibt das Resultat als String zurück.
    def request(req)
      begin
        socket = TCPSocket.new(@host, @port)
        socket.write(req)
        response = ""
        while !(chunk = socket.read(1024*64)).nil? && chunk.bytesize != 0
          response << chunk
        end
        socket.close
        
        if !response.nil? && response.empty?
          nil
        else
          response
        end
      rescue SystemCallError
        nil
      end
    end
  end
end
