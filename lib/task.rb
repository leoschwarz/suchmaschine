module Crawler
  module TaskState
    NEW = 0
    DONE = 1
    DISALLOWED = 2
  end
  
  # @stored_url -> URL die in der Datenbank gespeichert wird. Ohne HTTP/HTTPs Schema, aber mit dekodierten Sonderzeichen
  # @encoded_url -> URL mit kodierten Sonderzeichen (Beispiel: http://de.wikipedia.org/wiki/K%C3%A4se)
  # @decoded_url -> URL mit dekodierten Sonderzeichen, also ein UTF-8 string (Beispiel: http://de.wikipedia.org/wiki/Käse)
  
  class Task
    attr_reader :state, :done_at
  
    def initialize(stored_url, state, done_at)
      @stored_url = stored_url
      @state = state
      @done_at = done_at
    end
    
    def stored_url
      @stored_url
    end
    
    def encoded_url
      @_encoded_url ||= URI.encode decoded_url
    end
    
    def decoded_url
      @_decoded_url ||= "http://#{@stored_url}"
    end
    
    # Getter für den Domain namen der url
    def domain_name
      Domain.domain_name_of(encoded_url)
    end
    
    # Markiert den Task in der Datenbank als erledigt
    def mark_done
      Database.update(:tasklist, {url: stored_url}, {state: TaskState::DONE, done_at: DateTime.now})
    end
    
    # Markiet als verboten (wegen robots.txt)
    def mark_disallowed
      Database.update(:tasklist, {url: stored_url}, {state: TaskState::DISALLOWED, done_at: DateTime.now})
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
              Database.redis.get("domain.lastvisited.#{task.domain_name}").callback{|last_visited|
                last_visited = last_visited.to_f
                if (Time.now.to_f - last_visited) > Crawler.config.crawl_delay
                  succeed :ok
                else
                  succeed :not_ready
                end
              }.errback{|e| raise e}
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
        def do_link
          if @links.length > 0
            link = @links.pop
            Task.insert(link).callback{
              EM.next_tick{ self.do_link }
            }.errback{|e|
              raise e
            }
          else
            succeed
          end
        end
        
        def initialize(task)
          download = Download.new(task.encoded_url)
          download.callback { |response|
            Database.redis.set("domain.lastvisited.#{task.domain_name}", Time.now.to_f.to_s).callback{
            
              if response.header["location"].nil?
                html = response.body
                task.store_result(html)
                @links = HTMLParser.new(task.encoded_url, html).get_links
              
                do_link
              else
                url = URLParser.new(task.encoded_url, response.header["location"]).full_path
                Task.insert(url).callback{
                  task.mark_done.callback{
                    succeed 
                  }
                }
              end
            }.errback{|e| raise e}
          }
          download.errback { |error|
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
            succeed results.map{|result| Task.new(result["url"], nil, nil)}
          }.errback{|e|
            raise e
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
          if url.nil?
            succeed
          else
            Database.find(:tasklist, {url: url}, [:priority]).callback{ |results|
              if results.ntuples == 1
                # Es existiert bereits ein Eintrag, also Updaten
                # TODO: das erhöhen des wertes mit sql erledigen
                Database.update(:tasklist, {url: url}, {priority: results.first["priority"].to_i + 1}).callback{ succeed }.errback{|e| raise e}
              else
                # Es existiert noch kein Eintrag, also erstellen
                Database.insert(:tasklist, {url: url}).callback{ succeed }.errback{ |e|
                  if e.class == PG::UniqueViolation
                    # Etwas unschön, aber es kann passieren dass jemand schneller war als wir.
                    # Auf jeden Fall geht es jetzt darum den Eintrag zu aktualisieren.
                    Task.insert(url).callback{ succeed }
                  else
                    raise e
                  end
                }
              end
            }.errback{|e|
              raise e
            }
          end
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
      # Siehe: http://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
      decoded_url.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').gsub(%r{^https?://}, "")
    end
  end
end