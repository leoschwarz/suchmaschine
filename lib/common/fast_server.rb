# Wrapper für MulticlientTCPServer
# TODO Dies noch überarbeiten...

module Common
  class FastServer
    def initialize(host, port, logger=Logger.new)
      @host = host
      @port = port
      @logger = logger
      @on_request = proc{|request| }
      @on_start   = proc{}
      @on_stop    = proc{}
      @on_error   = proc{|error| raise error}
    end

    def start
      # Callback aufrufen
      @on_start.call

      # Server richtig starten
      @server = MulticlientTCPServer.new(@port, 5, false)
      @logger.log_info "Server gestartet unter #{@host}:#{@port}."
      loop do
        begin
          conn = @server.get_socket
          unless conn.nil?
            # Die Antwort generieren
            request  = conn.gets.strip
            response = @on_request.call(request)

            # Das Resultat schreiben und die Verbindung schliessen
            conn.puts response
          else
            sleep 0.01
          end
        rescue Errno::ECONNRESET, Errno::EPIPE
          @logger.log_error "Verbindung zu einem Client getrennt."
        rescue => e
          @on_error.call(e)
        rescue SystemExit, Interrupt
          @logger.log_info "Server wird heruntergefahren..."
          @on_stop.call
          raise SystemExit
        end
      end
    end

    def on_request(&block)
      @on_request = block
    end

    def on_start(&block)
      @on_start = block
    end

    def on_stop(&block)
      @on_stop = block
    end

    def on_error(&block)
      @on_error = block
    end
  end
end
