module Crawler
  module TaskState
    NEW = "0"
    SUCCESS = "1"
    FAILURE = "2"
  end
  
  class Task
    attr_reader :url, :state, :done_at
  
    def initialize(url, state=TaskState::NEW, done_at=nil)
      @url = url
      @state = state
      @done_at = done_at
    end
    
    # Gibt einen der folgenden Werte zurück:
    # :ok -> alles in Ordnung
    # :not_ready -> es muss noch gewartet werden
    # :not_allowed -> robots.txt verbietet das crawlen
    
    # TODO: Aktualisieren
    def get_state
      if RobotsParser.allowed?(@url.encoded)
#        last_visited = Database.redis.get("domain.lastvisited.#{domain_name}").to_f
#        if (Time.now.to_f - last_visited) > Crawler.config.crawl_delay
          return :ok
#        else
#          return :not_ready
#        end
      else
        return :not_allowed
      end
    end
    
    # Führt die Aufgabe aus und gibt true zurück falls die Aufgabe erfolgreich ausgeführt wurde.
    def execute
      download = Crawler::Download.new(@url)
            
      if download.success?
        if download.response_header["location"].nil?
          parser = HTMLParser.new(@url, download.response_body)
          
          # Ergebniss speichern
          document = Document.new(encoded_url: @url.encoded)
          document.timestamp      = Time.now.to_i
          document.index_allowed  = parser.indexing_allowed
          document.follow_allowed = parser.following_allowed
          document.links          = parser.links
          document.text           = parser.text
          document.save
          
          if parser.following_allowed
            Task.insert(parser.links.map{|link| link[1]})
          end    
        else
          url = URLParser.new(@url.encoded, download.response_header["location"]).full_path
          Task.insert([url])
        end
        
        return true
      else
        return false
      end      
    end
    
    # URLs an die Datenbank übergeben
    def self.insert(urls)
      Database.queue_insert urls.map{|url| url.stored}.select{|url| url.bytesize < 512}
    end
  end
end