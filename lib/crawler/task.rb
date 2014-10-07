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
        if download.redirect_url.nil?
          parser = HTMLParser.new(@url, download.response_body)
          links  = parser.links.map{|link| [link[0], link[1].stored]}
          
          # Ergebniss speichern
          document = Crawler::Document.new
          document.url   = @url.stored
          document.links = links
          document.text  = parser.text
          document.html  = parser.html
          document.save
          
          docinfo = Crawler::DocumentInfo.new
          docinfo.url = @url.stored
          docinfo.document = document
          docinfo.added_at = Time.now.to_i
          docinfo.permissions = {index: parser.indexing_allowed, follow: parser.following_allowed}
          docinfo.save
          
          if parser.following_allowed
            Task.insert(links.map{|pairs| pairs[1]})
          end    
        else
          destination_url = @url.join_with(download.redirect_url)
          Task.insert([destination_url.stored]) unless destination_url.nil?
          
          docinfo          = DocumentInfo.new
          docinfo.url      = @url.stored
          docinfo.redirect = destination_url.stored unless destination_url.nil?
          docinfo.added_at = Time.now.to_i
          docinfo.save
        end
        
        return :success
      else
        return :failure
      end      
    end
    
    # URLs an die Datenbank übergeben (im URL.stored Format)
    def self.insert(urls)
      Crawler::Database.download_queue_insert urls.select{|url| url.bytesize < 512}
    end
    
    def self.fetch
      Task.new(Crawler::Database.download_queue_fetch)
    end
  end
end