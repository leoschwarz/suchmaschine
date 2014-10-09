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
        socket.puts(req)
        response = socket.gets
        response.strip! unless response.nil?
        socket.close

        unless response.nil?
          if response.empty?
            response = nil
          end
        end

        response
      rescue SystemCallError
        nil
      end
    end
  end
end
