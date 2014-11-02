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
      unless RobotsTXT.allowed?(@url.encoded)
        return :not_allowed
      end

      download = Crawler::Download.new(@url, "text/html")
      if not download.success?
        # Der Download war nicht erfolgreich.
        :failure
      elsif download.redirect_url.nil?
        # Der Download war erfolgreich und es wird nicht weitergeleitet.
        parser = HTMLParser.new(@url, download.response_body)
        
        # Ergebniss speichern
        metadata = Crawler::Metadata.new
        metadata.url = @url
        metadata.title = parser.title
        metadata.downloaded  = parser.title_ok?
        metadata.added_at    = Time.now.to_i
        metadata.permissions = parser.permissions
        metadata.word_counts = WordCounter.new(parser.text).counts
        
        links = parser.links.map{|link| [link[0], link[1].stored]}
        if parser.following_allowed
          Task.insert(links.map{|pairs| pairs[1]})
        end
        
        if parser.title_ok?
          document = Crawler::Document.new
          document.url   = @url
          document.links = links
          document.title = parser.title
          document.text  = parser.text
          document.save
          metadata.downloaded = true
        else
          # Wir speichern Dokumente bei denen der Titel nicht in Ordnung ist gar nicht erst,
          # in Metadata wird dann vermerkt, dass das Dokument nicht heruntergeladen wurde.
          metadata.downloaded = false
        end

        metadata.save
        :success
      else
        # Der Download war erfolgreich, es handelt sich aber nur um eine Weiterleitung.
        destination_url = @url.join_with(download.redirect_url)
        Task.insert([destination_url.stored]) unless destination_url.nil?

        metadata            = Metadata.new
        metadata.url        = @url
        metadata.downloaded = false
        metadata.redirect   = destination_url.stored unless destination_url.nil?
        metadata.added_at   = Time.now.to_i
        metadata.save
        
        :success
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
