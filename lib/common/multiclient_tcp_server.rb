### Quelle: http://apps.jcns.fz-juelich.de/doku/sc/tcp_server_ruby

# TODO: Überarbeiten

### This is free software
### Placed in the public domain by Joachim Wuttke 2012

require 'socket'

module Common
  class MulticlientTCPServer
    # A nonblocking TCP server
    # - that serves several clients
    # - that is very efficient thanks to the 'select' system call
    # - that does _not_ use Ruby threads

    def initialize( port, timeout, verbose )
      @port = port        # the server listens on this port
      @timeout = timeout  # in seconds
      @verbose = verbose  # a boolean
      @connections = []
      begin
        @server = TCPServer.new( @port )
      rescue SystemCallError => ex
        raise "Cannot initialize TCP server for port #{@port}: #{ex}"
      end
    end

    def get_socket
      # Process incoming connections and messages.

      # When a message has arrived, we return the connection's TcpSocket.
      # Applications can read from this socket with gets(),
      # and they can respond with write().

      # one select call for three different purposes -> saves timeouts
      ios = select( [@server]+@connections, nil, @connections, @timeout )
      return nil unless ios

      # disconnect any clients with errors
      ios[2].each do |sock|
        sock.close
        @connections.delete( sock )
        raise "socket #{sock.peeraddr.join(':')} had error"
      end

      # accept new clients
      ios[0].each do |s|
        # loop runs over server and connections; here we look for the former
        if s != @server
          next
        end

        client = @server.accept
        raise "server: incoming connection, but no client" unless client

        @connections << client
        puts "server: incoming connection no. #{@connections.size} from #{client.peeraddr.join(':')}" if @verbose

        # give the new connection a chance to be immediately served
        ios = select( @connections, nil, nil, @timeout )
      end

      # process input from existing client
      ios[0].each do |s|
        # loop runs over server and connections; here we look for the latter
        if s == @server
          next
        end

        # since s is an element of @connections, it is a client created
        # by @server.accept, hence a TcpSocket < IPSocket < BaseSocket
        if s.eof?
          # client has closed connection
          puts "server: client closed #{s.peeraddr.join(':')}" if @verbose

          @connections.delete(s)
          next
        end

        puts "server: incoming message from #{s.peeraddr.join(':')}" if @verbose

        return s # message can be read from this
      end
      return nil # no message arrived
    end
  end
end
