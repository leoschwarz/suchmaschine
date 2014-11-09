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
        
        response = nil if !response.nil? && response.empty?
        resposne
      rescue SystemCallError
        nil
      end
    end
  end
end
