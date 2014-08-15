module Crawler
  module TaskState
    NEW = 0
    DONE = 1
    DISALLOWED = 2
  end
  
  class Task
    attr_reader :state, :done_at
  
    def initialize(encoded_url, state, done_at)
      @encoded_url = encoded_url
      @state = state
      @done_at = done_at
    end
  
    # Getter für die URL mit kodierten Sonderzeichen (ohne Sonderzeichen)
    def encoded_url
      @encoded_url
    end
  
    # Getter für die URL mit UTF-8 Sonderzeichen (mit Sonderzeichen)
    def decoded_url
      URI.decode(@encoded_url)
    end
    
    # Getter für den Domain namen der url
    def domain_name
      Domain.domain_name_of(encoded_url)
    end
    
    # Markiert den Task in der Datenbank als erledigt
    def mark_done
      Database.update(:tasklist, {url: decoded_url}, {state: TaskState::DONE, done_at: DateTime.now})
    end
    
    # Markiet als verboten (wegen robots.txt)
    def mark_disallowed
      Database.update(:tasklist, {url: decoded_url}, {state: TaskState::DISALLOWED, done_at: DateTime.now})
    end
  
    # TODO Dies ist nur eine provisorische "Lösung"
    def store_result(html)
      require 'digest/md5'
      filename = "./cache/html/#{Digest::MD5.hexdigest(decoded_url)}"
      f = open(filename, "w")
      f.write(html)
      f.close
      mark_done
    end
    
    # Ruft ein callback auf mit einem der Werte:
    # :ok -> alles in Ordnung
    # :not_ready -> es muss noch gewartet werden
    # :not_allowed -> robots.txt verbietet das crawlen
    def get_state
      Class.new {
        include EM::Deferrable
        def initialize(task)
          RobotsParser.allowed?(task.encoded_url).callback{|allowed|
            if allowed
              last_visited = Database.redis.get("domain.lastvisited.#{task.domain_name}").to_f
              if (Time.now.to_f - last_visited) > Crawler.config.crawl_delay
                succeed :ok
              else
                succeed :not_ready
              end
            else
              succeed :not_allowed
            end
          }
        end
      }.new(self)
    end
    
    def execute
      Class.new {
        include EM::Deferrable
        def initialize(task)
          task_url = "http://" + task.encoded_url
          request = EM::HttpRequest.new(task_url).get(timeout: 10, head: {user_agent: Crawler.config.user_agent})
          request.callback {
            header = request.response_header
            Database.redis.set("domain.lastvisited.#{task.domain_name}", Time.now.to_f.to_s)
            
            if header["location"].nil?
              html = request.response
              links = HTMLParser.new(task.encoded_url, html).get_links
              links.each {|link| Task.insert(link)} # TODO: Auf callback warten
              task.store_result(html)
              succeed
            else
              url = URLParser.new(task.encoded_url, header["location"]).full_path
              Task.insert(url).callback{
                task.mark_done.callback{
                  succeed 
                }
              }
            end
          }
          request.errback { |error|
            fail error
          }
        end
      }.new(self)
    end
    
    # Lädt ein Sample URLs die noch nicht abgerufen wurden und deren Domains wieder aufgerufen werden dürfen.
    # Gibt ein Deferrable zurück welches mit einem Array von Task Instanzen aufgerufen wird.
    def self.sample(n=100)
      # FIXME: Zufallsauswahl
      # Idee:  Man könnte eine Spalte random einführen. Dort wird jeweils beim Schreiben in die Tabelle ein Zufallswert hineingesetzt.
      #        Diesen Zufallswert kombiniert man nun noch mit einer Stundenzahl oder so. Jetzt werden alle Einträge für die kleinste
      #        Stunde abgearbeitet, währned zu einem höheren Wert neue Einträge hinzugefügt werden. Hierdurch kann man vermeiden, dass 
      #        neue Einträge mit einem kleineren Zufallswert (beispielsweise) immer gecrawlt werden, während andere endlos darauf warten.
      
      Class.new {
        include EM::Deferrable
        def initialize(n)
          Database.query("SELECT url FROM tasklist WHERE state = #{TaskState::NEW} ORDER BY priority DESC LIMIT #{n}").callback{ |results|
            succeed results.map{|result| Task.new(URI.encode(result["url"]), nil, nil)}
          }.errback{|e|
            throw e
          }
        end
      }.new(n)
    end
  
    # Fügt eine neue URL der Datenbank hinzu.
    # Falls die URL bereits existiert, wird deren Priorität erhöht.
    def self.insert(encoded_url)
      Class.new {
        include EM::Deferrable
        def initialize(url)
          succeed if url.nil?
          
          Database.find(:tasklist, {url: url}, [:priority]).callback{ |results|
            if results.ntuples == 1
              # Es existiert bereits ein Eintrag, also Updaten
              Database.update(:tasklist, {url: url}, {priority: results.first["priority"] + 1}).callback{ succeed }
            else
              # Es existiert noch kein Eintrag, also erstellen
              Database.insert(:tasklist, {url: url}).callback{ succeed }
            end
          }
        end
      }.new(_prepare_url_for_insert(encoded_url))
    end
    
    private
    # Alle URLs sollen in ein einheitliches Format umgewandelt werden.
    # - Das Schema wird von den URLs entfernt. (http://www.example.com -> www.example.com)
    # - Der Fragment Identifier wird entfernt. (example.com/index.html#news -> example.com/index.html)
    def self._prepare_url_for_insert(encoded_url)
      # Überprüfen ob nil
      return nil if encoded_url.nil?
      decoded_url = URI.decode encoded_url
      
      # Länge überprüfen
      return nil if decoded_url.length > 512
      
      # Fragment Identifier wurde bereits von URLParser entfernt.
      
      # Schema entfernen
      decoded_url.gsub(%r{^https?://}, "")
    end
  end
end