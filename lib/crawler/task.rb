module Crawler
  class Task
    attr_reader :url
  
    def initialize(url)
      @url = url
    end
    
    # Bearbeitet die URL und gibt einen der folgedenen Werte zurück:
    # :success -> Alles lief einwandfrei.
    # :failure -> Es gab einen Fehler beim Download. (zBsp. ein HTTP-Fehler)
    # :not_allowed -> Die URL darf nicht heruntergeladen werden
    def execute
      # Überprüfen ob es erlaubt ist die Seite herunterzuladen
      unless RobotsParser.allowed?(@url.encoded)
        return :not_allowed
      end
      
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
            Task.insert(parser.links.map{|link| URL.encoded link[1]})
          end    
        else
          url = URLParser.new(@url.encoded, download.response_header["location"]).full_path
          Task.insert([URL.encoded(url)])
        end
        
        return :success
      else
        return :failure
      end      
    end
    
    # URLs an die Datenbank übergeben
    def self.insert(urls)
      Database.queue_insert urls.map{|url| url.stored}.select{|url| url.bytesize < 512}
    end
  end
end