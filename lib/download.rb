class Download
  def initialize(task)
    @task = task
  end
  
  def run
    time_start = Time.now
    uri  = URI.parse(@task.encoded_url)
    http = Net::HTTP.new(uri.host, uri.port)
    path = uri.path.empty? ? "/" : uri.path
    
    http.request_get(path) do |response|
      if response["content-type"].include? "text/html"
        if response["location"].nil?
          html = response.read_body
          parser = HTMLParser.new(@task, html)
          links  = parser.links
          links.each {|link| Task.insert(URI.decode link)}
          @task.store_result(html)
        else
          url = URLParser.new(@task.encoded_url, response["location"]).full_path
          Task.insert(URI.decode(url))
        end
      end
    end
    
    @task.mark_done
    time_end = Time.now
    @time = time_end - time_start
  end
  
  def time
    @time
  end
end