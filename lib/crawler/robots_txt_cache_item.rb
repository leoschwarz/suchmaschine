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
    
    def self.db
      # TODO: Konfigurationsauslagerung!
      @@db ||= RocksDB::DB.new "cache/robotstxt"
    end
    
    def save
      if Crawler.config.robots_txt.use_cache
        data = Oj.dump(@rules, {mode: :object})
        
        self.db.put("data:#{domain}", data)
        self.db.put("valid:#{domain}", valid_until.to_s)
      end
    end
    
    def set_valid_for(seconds)
      if seconds == :default
        @valid_until = Time.now.to_i + Crawler.config.robots_txt.cache_lifetime
      else
        @valid_until = Time.now.to_i + seconds
      end
    end
    
    # Sucht nach einem robots.txt Cache-Eintrag für eine bestimmte Domain.
    # Falls ein noch gültiger Cacheintrag gefunden wird, wird dieser als Erfolg zurück gegeben, falls dieser bereits ungültig wurde wird :outdated und falls gar keiner vorhanden ist mit :none zurückgegeben.
    def self.for_domain(domain)
      unless Crawler.config.robots_txt.use_cache
        return RobotsTxtCacheItem.new(domain, "[]", :not_found, nil)
      end
      
      data  = self.db.get("data:#{domain}")
      valid = self.db.get("valid:#{domain}").to_i
      status = nil
      
      if data.nil?
        data = "[]"
        status = :not_found
      else
        status = valid > Time.now.to_i
      end
      
      RobotsTxtCacheItem.new(domain, data, status, valid)
    end
  end
end