############################################################################################
# Die Download Klasse abstrahiert die Verwendung der Curb Bibliothek, welche ein Binding   #
# für eine native Implementierung eines HTTP Clients, der libcurl Bibliothek, ist.         #
#                                                                                          #
# Folgende Funktionen werden von der Download Klasse übernommen:                           #
# - Es wird versucht die Antwort in einen UTF-8 String zu konvertieren.                    #
# - Es kann ein Content-Type vorausgesetzt werden, sollte dieser nicht zutreffen, wird der #
#   Download vorzeitig abgebrochen.                                                        #
# - Der Download wird abgebrochen, wenn eine maximale Antwortgrösse überschritten wird.    #
############################################################################################
require 'curb'
module Crawler
  class Download
    # Das hier ist leider nicht perfekt, da es verschiedene Schreibweisen für die
    # verschiedenen Kodierungen gibt und somit einige deshalb nicht erkannt werden.
    SUPPORTED_ENCODINGS = (::Encoding.name_list.map{|name| name.downcase}+["utf8"]).freeze
    
    # Getter für entsprechende Attribute
    attr_reader :redirect_url, :response_body, :status
    
    # @param url [Common::URL] Download-URL
    # @param force_type [String,nil] Falls gegeben: Die Antwort muss diesen Content-Type
    #   haben, ansonsten wird der Download frühzeitig abgebrochen.
    def initialize(url, force_type=nil)
      # Download durchführen.
      if perform_download(url, force_type)
        # Die Library gibt einen String mit ASCII-8BIT Kodierung zurück.
        # Dieser muss nun nach UTF-8 konvertiert werden:
        # 1. Eventuelle Content-Type Kodierung verwenden.
        original_encoding = @response_body.encoding
        match = /charset=([\w\d-]+)/.match(@content_type.downcase)
        if match != nil and SUPPORTED_ENCODINGS.include?(encoding = match[1].downcase)
          encoding = "UTF-8" if encoding.include? "utf8"
          @response_body.force_encoding(encoding)
          @response_body.encode!('utf-8', invalid: :replace, undef: :replace, replace: '')
        # 2. Falls der String mit UTF-8 Kodierung korrekt ist, nehmen wir einfach an es
        #    handle sich um UTF-8 (das einfach von der Library als ASCII angegeben wurde).
        elsif @response_body.force_encoding('utf-8').valid_encoding?
          @response_body = @response_body.force_encoding("utf-8")
        # 3. Falls gar nichts funktioniert, werden einfach alle falschen Bytes entfernt.
        #    Das heisst alle Zeichen die es in ASCII nicht gibt aber falsch kodiert wurden
        #    werden entfernt, auch wenn es diese Zeichen in der UTF-8 Kodierung gäbe.
        # Siehe: http://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
        #        http://www.ruby-doc.org/core-2.0/String.html
        else
          options = {invalid: :replace, undef: :replace, replace: ''}
          @response_body.force_encoding(original_encoding).encode!('UTF-8', options)
        end
      end
    end

    def success?
      @success
    end
    
    private
    def perform_download(url, force_type = nil)
      # Standardwerte setzen.
      @response_body = ""
      @response_body_size = 0
      @redirect_url = nil
      @status = "500"
      @success = false
      @content_type = ""
      
      # Download durchführen.
      begin
        type_checked = false
        dl = Curl::Easy.new(url.encoded) do |curl|
          curl.headers["User-Agent"] = Config.crawler.agent
          curl.verbose = false
          curl.timeout = Config.crawler.timeout
          curl.encoding = "UTF-8"

          curl.on_body {|chunk|
            @content_type = curl.content_type.downcase
            if force_type && !type_checked
              if @content_type.include?(force_type)
                type_checked = true
              else
                return false
              end
            end
          
            size = chunk.bytesize
            if @response_body_size+size <= Config.crawler.maxsize
              @response_body += chunk
              @response_body_size + size
              size
            else
              -1
            end
          }
        end
        dl.perform
        
        @status       = dl.status
        @success      = @status[0] == "2"
        @redirect_url = url.join_with(dl.redirect_url) unless dl.redirect_url == -1
        
        return true
      rescue
        return false
      end
    end
  end
end
