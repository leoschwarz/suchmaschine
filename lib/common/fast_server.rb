require 'socket'

module Common
  class FastServer
    def initialize(host, port)
      @host = host
      @port = port
      
      @on_request = proc{|request| }
      @on_start   = proc{}
      @on_stop    = proc{}
    end
    
    def start
      # Callback aufrufen
      @on_start.call
      puts "Server gestartet unter #{@host}:#{@port}."
      
      # Server richtig starten
      @server = TCPServer.new(@host, @port)
      loop do
        begin
          # Auf einen Client warten
          @conn = @server.accept
          
          # Die Antwort generieren
          request  = @conn.gets.strip
          response = @on_request.call(request)
          
          # Das Resultat schreiben und die Verbindung schliessen
          @conn.puts response
          @conn.close
          @conn = nil
        rescue SystemExit, Interrupt
          puts "Server wird heruntergefahren..."
          @on_stop.call
          raise SystemExit
        rescue => exception
          # TODO Fehlermanagment (Logfile etc.)
          unless @conn.nil?
            @conn.close
            @conn = nil
          end
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
  end
end