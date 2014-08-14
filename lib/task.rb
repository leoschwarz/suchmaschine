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
          Database.query("SELECT url FROM tasklist INNER JOIN domains ON tasklist.domain = domains.domain WHERE state = #{TaskState::NEW} AND ignore_until < CURRENT_TIMESTAMP LIMIT #{n}").callback{ |results|
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
      
      domain_name = Domain.domain_name_of(decoded_url)
      Database.insert_if_not_exists(:domains, {domain: domain_name}, [:domain]).callback{
        Database.insert_if_not_exists(:tasklist, {url: decoded_url, domain: domain_name, state: TaskState::NEW}, [:url])
      }
    end
  end
end