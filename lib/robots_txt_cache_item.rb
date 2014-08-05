require 'oj'
require 'date'

module Crawler
  # Das Attribut Status kann folgende Werte annehmen:
  # :ok
  # :outdated
  # :not_found
  
  class RobotsTxtCacheItem
    attr_accessor :domain, :status, :rules
    
    def initialize(domain, serialized_data, status, valid_until)
      @domain = domain
      @rules = Oj.load(serialized_data, {mode: :object}).map{|rule| [rule[0].to_sym, rule[1]]}
      @status = status
      @valid_until = valid_until
    end
    
    def save
      if Crawler.config.robotstxt.use_cache
        data = Oj.dump(@rules, {mode: :object})
        if @status == :ok or @status == :outdated
          return Database.update(:robotstxt, {domain: @domain}, {data: data, valid_until: @valid_until})
        else
          return Database.insert(:robotstxt, {domain: @domain, data: data, valid_until: @valid_until})
        end
      end
      Class.new{
        include EM::Deferrable
        def initialize
          succeed
        end
      }.new
    end
    
    def set_valid_for(seconds)
      if seconds == :default
        @valid_until = DateTime.now + Rational(Crawler.config.robotstxt.cache_lifetime, 86400)
      else
        @valid_until = DateTime.now + Rational(seconds, 86400)
      end
    end
    
    # Sucht nach einem robots.txt Cache-Eintrag für eine bestimmte Domain.
    # Gibt ein Deferrable zurück, falls ein noch gültiger Cacheintrag gefunden wird, wird dieser als Erfolg zurück gegeben, falls dieser bereits ungültig wurde wird ein Fehler mit :outdated und falls gar keiner vorhanden ist mit :none aufgerufen.
    def self.for_domain(domain)
      Class.new {
        include EM::Deferrable
        
        def initialize(domain)
          if Crawler.config.robotstxt.use_cache
            Database.select(:robotstxt, {domain: domain}, [:data, :valid_until]).callback{ |result|
              data = "[]"
              valid_unitl = nil
              status = :not_found
              if result.ntuples == 1
                data = result[0]["data"]
                valid_until = DateTime.parse(result[0]["valid_until"])
                status = valid_until > DateTime.now ? :ok : :outdated
              end
              succeed RobotsTxtCacheItem.new(domain, data, status, valid_until)
            }
          else
            succeed RobotsTxtCacheItem.new(domain, "[]", :not_found, nil)
          end
        end
      }.new(domain)
    end
  end
end