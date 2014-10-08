require 'curb'

module Crawler
  class Download
    attr_reader :redirect_url, :response_body, :status
    
    def initialize(url)
      @response_body = ""
      @response_body_size = 0
      @success = true
      
      begin
        curl = Curl::Easy.new(url.encoded) do |curl|
          curl.headers["User-Agent"] = Crawler.config.user_agent
          curl.verbose = false
          curl.timeout = 10
          curl.encoding = "UTF-8"
          
          curl.on_body {|chunk|
            size = chunk.bytesize
            if @response_body_size+size <= Crawler.config.max_response_length
              @response_body += chunk
              @response_body_size + size
              size
            else
              -1
            end
          }
        end
        curl.perform
        
        # UTF-8 Kodierung sicherstellen,
        # Der String @response_body ist normalerweise ASCII-8BIT:
        # 1. UTF-8 Kodierung annehmen, und auf Korrektheit überprüfen:
        if @response_body.force_encoding("UTF-8").valid_encoding?
          @response_body = @response_body.force_encoding("UTF-8")
        else
          # 2. Falls dies nicht funktioniert hat, werden nun einfach alle falschen Bytes entfernt.
          #    Das heisst, beispielsweise deutsche Umlaute könnten verschwinden, sollten sie in 
          #    einer anderen Kodierung als UTF-8 vorlieren. (zBsp: ISO-LATIN-1)
          #
          # Siehe: http://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
          #        http://www.ruby-doc.org/core-2.0/String.html
          @response_body.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '')
        end
      rescue Exception => e
        @success  = false
        @status   = "500"
        @redirect = nil
        return
      end
      
      # Die Library spuckt leider manchmal Fehler aus, wenn etwas nicht klappt...
      begin
        @success = curl.status[0] == "2" 
      rescue Exception
        @success = false
      end
      
      begin
        @status = curl.status
      rescue Exception
        @status = "500"
      end
      
      begin
        @redirect = curl.redirect_url unless curl.redirect_url == -1
      rescue Exception
        @redirect = nil
      end
    end
    
    def success?
      @success
    end
  end
end
