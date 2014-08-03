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
    
    # Getter für den Domain namen der url
    def domain_name
      Domain.domain_name_of(encoded_url)
    end
    
    # Markiert den Task in der Datenbank als erledigt
    def mark_done
      Domain.for_url(encoded_url).callback do |domain|
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
          Database.query("SELECT url FROM tasklist INNER JOIN domains ON tasklist.domain = domains.domain WHERE state = 0 AND ignore_until < CURRENT_TIMESTAMP LIMIT #{n}").callback{ |results|
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
      
      # Überprüfen ob URL bereits in der Datenbank eingetragen ist
      self.registered?(decoded_url).callback{ |registered|
        unless registered
          # Überprüfen ob Domain bereits in der Datenbank eingetragen ist
          domain_name = Domain.domain_name_of(decoded_url)
          Domain.registered?(domain_name).callback{ |domain_registered|
            if domain_registered
              Database.insert(:tasklist, {url: decoded_url, domain: domain_name, state: 0})
            else
              Database.insert(:domains, {domain: domain_name}).callback{
                Database.insert(:tasklist, {url: decoded_url, domain: domain_name, state: 0})
              }
            end
          }
        end
      }
    end
  end
end