require 'date'

module Crawler
  class Domain
    attr_reader :name, :last_scheduled
  
    def initialize(name, last_scheduled)
      @name = name
      if last_scheduled.nil?
        @last_scheduled = DateTime.now
      else
        @last_scheduled = DateTime.parse(last_scheduled)
      end
    end
  
    def mark_time!
      @last_scheduled = DateTime.now
      Database.update(:domains, {domain: @name}, {last_scheduled: @last_scheduled})
    end
    
    def allowed?
      @last_scheduled < DateTime.now - Rational(1, 60*60*24)
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
    # Gibt ein Deferable Objekt zurück, welches beim callback mit dem Domain Objekt aufgerufen wird.
    def self.for(domain_name)
      Class.new {
        include EM::Deferrable
        
        def initialize(domain_name)
          Database.select(:domains, {"domain" => domain_name}, ["last_scheduled"]).callback { |result|
            if result.ntuples == 1
              puts Domain.new(domain_name, result[0]["last_scheduled"]).inspect
              succeed(Domain.new(domain_name, result[0]["last_scheduled"]))
            elsif result.ntuples == 0
              Database.insert(:domains, {domain: domain_name, last_scheduled: "CURRENT_TIMESTAMP"}).callback do
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