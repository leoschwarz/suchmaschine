class Download
  include EM::Deferrable
  
  def initialize(encoded_url)
    @response_data = ""
    @header = nil
    @http = EM::HttpRequest.new(encoded_url).get(timeout: 10, head: {user_agent: Crawler.config.user_agent})
    @http.callback{ self.on_callback }
    @http.errback{|error| fail error }
    @http.stream{|chunk| self.on_chunk(chunk) }
  end
  
  def on_callback
    succeed self
  end
  
  def on_chunk(chunk)
    @response_data += chunk
    
    if @response_data.bytesize >= Crawler.config.max_response_length
      succeed self
    end
  end
  
  def body
    @response_data
  end
  
  def header
    @http.response_header
  end
  
  def code
    header.http_status.to_s
  end
end