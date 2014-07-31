module Crawler
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
    
    # Gibt Auskunft ob es erlaubt ist die URL zu crawlen
    # Gibt ein Deferrable zurück, dass mit einem Bool Wert aufgerufen wird
    def allowed?
      Class.new {
        include EM::Deferrable
        def initialize
          Domain.for(encoded_url).callback { |domain|
            self.succeed(domain.allowed?)
          }
        end
      }.new
    end
    
    # Markiert den Task in der Datenbank als erledigt
    def mark_done
      Domain.for(encoded_url).callback do |domain|
        domain.mark_time!
        Database.update(:tasklist, {url: decoded_url}, {state: 1, done_at: DateTime.now})
      end
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
    
    # Überprüft ob eine URL bereits in der Datenbank registriert ist.
    # Gibt ein Deferrable zurück welches mit einem Bool-Wert augerufen wird.
    def self.registered?(decoded_url)
      Class.new {
        include EM::Deferrable
        def initialize(decoded_url)
          Database.select(:tasklist, {url: decoded_url}, ["url"]).callback { |result|
            self.succeed(result.ntuples > 0)
          }
        end
      }.new(decoded_url)
    end
  
    def self.sample(n=100)
      # FIXME: Zufallsauswahl
      # Idee:  Man könnte eine Spalte random einführen. Dort wird jeweils beim Schreiben in die Tabelle ein Zufallswert hineingesetzt.
      #        Diesen Zufallswert kombiniert man nun noch mit einer Stundenzahl oder so. Jetzt werden alle Einträge für die kleinste
      #        Stunde abgearbeitet, währned zu einem höheren Wert neue Einträge hinzugefügt werden. Hierdurch kann man vermeiden, dass 
      #        neue Einträge mit einem kleineren Zufallswert (beispielsweise) immer gecrawlt werden, während andere endlos darauf warten.
    
      Class.new {
        include EM::Deferrable
        def initialize(n)
          Database.select(:tasklist, {state: 0}, ["url"], n).callback { |results|
            succeed results.map{|result| Task.new(URI.encode(result["url"]), nil, nil)}
          }
        end
      }.new(n)
    end
    
    def self.fetch
      Class.new {
        include EM::Deferrable
        def initialize
          Task.sample(1).callback{|tasks|
            succeed(tasks.first)
          }.errback{
            fail
          }
        end
      }.new
    end
  
    # Fügt eine neue URL der Datenbank hinzu.
    def self.insert(decoded_url)
      # Länge überprüfen
      if decoded_url.length > 512
        return nil
      end
      
      # TODO Überprüfen ob URL gültig ist. (Das würde dann in allen Fällen verhindern, dass Domain.for(..) -> nil sein könnte)
      
      # Überprüfen ob url bereits in der Datenbank eingetragen ist
      self.registered?(decoded_url).callback{ |registered|
        unless registered
          Database.insert(:tasklist, {url: decoded_url, state: 0})
        end
      }
    end
  end
end