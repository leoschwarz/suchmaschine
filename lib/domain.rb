require 'date'

module Crawler
  
  # Information:
  # In der Datenbank wird neuerdings ein Feld ignore_until für die Domain gespeichert.
  # Dieses Feld wird aktualisiert sobald die Warteschleife wieder mit neuen Elementen aufgefüllt wird.
  # Für jeden Seitenaufruf auf einer bestimmten Domain wird eine Sekunde Wartezeit eingerechnet, bis die Domain
  # erneut aufgerufen wird.
  
  class Domain
    attr_reader :name, :ignore_until
  
    def initialize(name, ignore_until)
      @name = name
      if ignore_until.nil?
        @ignore_until = DateTime.new # t = 0, es wird also auf jeden Fall nicht ignoriert
      else
        @ignore_until = DateTime.parse(ignore_until)
      end
    end
    
    # Ändert den Eintrag für die Domain, sodass sie innerhalb der nächsten n Sekunden nicht mehr aufgerufen wird.
    def ignore_for(seconds)
      @ignore_until = DateTime.now + Rational(seconds,86400)
      Database.update(:domains, {domain: @name}, {ignore_until: @ignore_until})
    end
    
    # Hilfsmethode um den Domain Namen einer URL zu extrahieren.
    def self.domain_name_of(url)
      match = /https?:\/\/([a-zA-Z0-9\.-]+)/.match(url)
      if not match.nil?
        domain_name = match[1].downcase
      else
        return nil
      end
    end
    
    # Lädt ein Domain Objekt aus der Datenbank für den angegebenen Domain Namen.
    # Gibt eine Deferrable Instanz zurück, welches beim Callback mit dem Domain Objekt aufgerufen wird.
    def self.for(domain_name)
      Class.new {
        include EM::Deferrable
        
        def initialize(domain_name)
          Database.find(:domains, {"domain" => domain_name}, ["ignore_until"]).callback { |result|
            if result.ntuples == 1
              succeed(Domain.new(domain_name, result[0]["ignore_until"]))
            elsif result.ntuples == 0
              Database.insert(:domains, {domain: domain_name, ignore_until: "CURRENT_TIMESTAMP"}).callback do
                succeed(Domain.new(domain_name, nil))
              end
            else
              fail("ERROR: Domain #{domain_name} ist #{result.ntuples} in der Datenbank registriert!")
            end
          }
        end
      }.new(domain_name)
    end
    
    # Lädt ein Domain Objekt aus der Datenbank für die angegebene URL.
    def self.for_url(url)
      self.for(self.domain_name_of(url))
    end
  end
end