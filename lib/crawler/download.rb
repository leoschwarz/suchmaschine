require 'curb'

module Crawler
  class Download
    # TODO: Nur diese Kodierungen zulassen (ist aber leider etwas kompliziert,
    # da man verschiedene Schreibweisen der Kodierungen kennt. beispielsweise bei utf-8)
    SUPPORTED_ENCODINGS = ::Encoding.name_list.map{|name| name.downcase}.freeze
    
    attr_reader :redirect_url, :response_body, :status

    # url: [URL]
    # force_type: [nil/String] entweder nil (es ist egal um was für einen Content-Type es sich handelt)
    #                          oder String (es muss sich um diesen Content-Type handeln.)
    def initialize(url, force_type=nil)
      # Download durchführen.
      if perform_download(url, force_type)
        # UTF-8 Kodierung sicherstellen,
        # Der String @response_body ist normalerweise ASCII-8BIT.
        # 1. Falls im Content-Type Feld eine Kodierung festgelegt wurde, wird diese verwendet.
        original_encoding = @response_body.encoding
        if not (match = /charset=([\w\d-]+)/.match(@content_type.downcase)).nil?
    #      and SUPPORTED_ENCODINGS.include?((encoding = match[1].downcase))
          encoding = match[1].downcase
          encoding = "UTF-8" if encoding.include? "utf8"
          @response_body.force_encoding(encoding)
          @response_body.encode!('utf-8', invalid: :replace, undef: :replace, replace: '')
        # 2. Falls der String mit UTF-8 Kodierung korrekt ist, nehmen wir einfach an es
        #    handle sich um UTF-8 (das einfach von der Library als ASCII angegeben wurde).
        elsif @response_body.force_encoding('utf-8').valid_encoding?
          @response_body = @response_body.force_encoding("utf-8")
        # 3. Falls gar nichts funktioniert, werden einfach alle falschen Bytes entfernt.
        #    Das heisst alle Zeichen die es in ASCII nicht gibt aber falsch kodiert wurden
        #    werden entfernt, auch wenn es diese Zeichen eigentlich in der UTF-8 Kodierung gäbe.
        # Siehe: http://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
        #        http://www.ruby-doc.org/core-2.0/String.html
        else
          @response_body.force_encoding(original_encoding).encode!('UTF-8', invalid: :replace, undef: :replace, replace: '')
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
