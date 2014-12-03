############################################################################################
# Eine Task - eine Aufgabe - abstrahiert die eigentliche Arbeit des Crawlers.              #
# Vom Client wird eine Aufgabe geladen, welche dann ausgeführt wird, was heisst dass die   #
# Methode 'execute' aufgerufen wird. Die Resultate werden selbstständig in die Datenbank   #
# geschrieben.                                                                             #
############################################################################################
module Crawler
  class Task
    # Erzeugt eine neue Aufgabe.
    # @param url [URL] URL der Aufgabe.
    def initialize(url)
      @url = url
    end

    # Führt die Aufgabe aus.
    # @return [Symbol] :success -> Alles lief einwandfrei.
    #                  :failure -> Es gab einen (HTTP-)Fehler beim Download.
    #                  :not_allowed -> Die URL darf nicht heruntergeladen werden.
    def execute
      # Überprüfen ob es erlaubt ist die Seite herunterzuladen
      unless Robotstxt.allowed?(@url)
        return :not_allowed
      end
      
      # Den Download durchführen.
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
        
        if parser.permissions[:follow]
          # Links einfügen, aber zuvor werden die Fragmentbezeichner aus den URLs entfernt,
          # um unnötige Duplikate zu verhindern.
          Task.insert(parser.links.map{ |anchor, url|
            url.remove_fragment_identifier
            url.stored
          })
        end
        
        if parser.title_ok?
          document = Crawler::Document.new
          document.url   = @url
          document.links = parser.links.map{|anchor, url| [anchor, url.stored]}
          document.title = parser.title
          document.text  = parser.text
          document.save
          metadata.downloaded = true
          metadata.save
          
          Crawler::Database.index_queue_insert([metadata.hash])
        else
          # Wir speichern Dokumente bei denen der Titel nicht in Ordnung ist gar nicht erst,
          # in Metadata wird dann vermerkt, dass das Dokument nicht heruntergeladen wurde.
          metadata.downloaded = false
          metadata.save
        end
        
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

    # Neue Aufgaben erstellen.
    # @param urls [Array] URLs im stored Format (ohne Fragmentbezeichner)
    # @return [nil]
    def self.insert(urls)
      Crawler::Database.download_queue_insert urls.select{|url| url.bytesize < 512}
    end

    # Neue Aufgabe laden.
    # @return [Task]
    def self.fetch
      Task.new(Crawler::Database.download_queue_fetch)
    end
  end
end
