require 'oj'
require 'date'

module Crawler
  # Das Attribut Status kann folgende Werte annehmen:
  # :ok
  # :outdated
  # :not_found
  
  class RobotsTxtCacheItem
    attr_accessor :domain, :status, :rules
    
    def initialize(domain, rules, status, valid_until)
      @domain = domain
      @rules = rules.map{|rule| [rule[0].to_sym, rule[1]]}
      @status = status
      @valid_until = valid_until
    end
    
    def save
      if Crawler.config.robots_txt.use_cache
        data = Oj.dump({valid_until: @valid_until, rules: @rules}, {mode: :object})        
        Database.cache_set("robotstxt:#{domain}", data)
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
      
      data   = Crawler::Cache.get("robotstxt:#{domain}")
      rules  = []
      status = :not_found
      valid_until = nil
      
      unless data.nil?
        deserialized = Oj.load(data, {mode: :object})
        valid_until  = deserialized[:valid_until]
        rules        = deserialized[:rules]
        status = valid_until > Time.now.to_i
      end
      
      RobotsTxtCacheItem.new(domain, data, status, valid_until)
    end
  end
end