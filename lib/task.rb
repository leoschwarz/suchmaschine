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
          Database.query("SELECT url FROM tasklist WHERE state = #{TaskState::NEW} LIMIT #{n}").callback{ |results|
            succeed results.map{|result| Task.new(URI.encode(result["url"]), nil, nil)}
          }.errback{|e|
            throw e
          }
        end
      }.new(n)
    end
  
    # Fügt eine neue URL der Datenbank hinzu.
    def self.insert(decoded_url)
      # Länge überprüfen
      if decoded_url.length > 512
        return nil
      end
      
      Database.insert_if_not_exists(:tasklist, {url: decoded_url, state: TaskState::NEW}, [:url])
    end
  end
end