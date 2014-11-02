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
          curl.headers["User-Agent"] = Config.crawler.agent
          curl.verbose = false
          curl.timeout = Config.crawler.timeout
          curl.encoding = "UTF-8"

          curl.on_body {|chunk|
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
        curl.perform

        # UTF-8 Kodierung sicherstellen,
        # Der String @response_body ist normalerweise ASCII-8BIT.
        # 1. Falls im Content-Type Feld eine Kodierung festgelegt wurde, wird diese verwendet.
        if not (match = /charset=([\w\d-]+)/.match(curl.content_type.downcase)).nil?
          encoding = match[1]
          @response_body.force_encoding!(encoding)
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
          @response_body.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '')
        end
      rescue
      end

      @status       = "500"
      @success      = false
      @redirect_url = nil

      begin
        @status       = curl.status
        @success      = @status[0] == "2"
        @redirect_url = url.join_with(curl.redirect_url) unless curl.redirect_url == -1
      rescue
      end
    end

    def success?
      @success
    end
  end
end
