require 'socket'
require 'uri'

# TODO: Weiterleitungsmanagment! (3xx-Redirect)

module Crawler
  class Download
    attr_accessor :response_header, :response_body, :uri
    
    def initialize(encoded_url)
      @uri = URI(encoded_url)
      @raw_response = ""
      
      # Den Socket öffnen
      socket = TCPSocket.open(@uri.host, @uri.port)
      socket.print "GET #{@uri.path} HTTP/1.1\r\n"
      socket.print "User-Agent: #{Crawler.config.user_agent}\r\n"
      socket.print "Host: #{@uri.host}\r\n"
      socket.print "Accept: text/html\r\n"
      socket.print "Accept-Charset: utf-8\r\n"
      socket.print "\r\n"
      
      # Die Antwort abfragen
      while not (chunk = socket.recv(16384)).empty? and @raw_response.bytesize < Crawler.config.max_response_length
        @raw_response += chunk
      end
      
      # Die Antwort einlesen
      parse_response(@raw_response)
    end
    
    def success?
      # TODO: 3xx-Weiterleitung
      @header["status-code"][0] == "2" or @header["status-code"][0] == "3"
    end
    
    private
    def parse_response(raw_response)
      @response_header = {}
      @respone_body    = ""
      
      # Aufteilen in Header und Body
      separator      = raw_response.index("\r\n\r\n")
      raw_header     = raw_response[0...seperator]
      @response_body = raw_response[seperator+1..-1]
      
      # Verarbeitung des Headers
      lines = raw_header.split("\r\n")
      first_line = lines.first.split(" ") # ["HTTP/1.1", "200", "OK"]
      if first_line[0] != "HTTP/1.1"
        raise "HTTP bitte! #{first_line[0]}"
      end
      @response_header["status-code"] = first_line[1]
      @response_header["status-message"] = first_line[2]
      lines[1..-1].each do |line|
        parts = line.split(":")
        @response_header[parts[0].downcase] = parts[1]
      end
    end 
  end
end