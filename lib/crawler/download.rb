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
      rescue Exception => e
        @success = false
        return
      end
      
      @success  = curl.status[0] == "2"
      @redirect = curl.redirect_url unless curl.redirect_url == -1
      @status   = curl.status
    end
    
    def success?
      @success
    end
  end
end
