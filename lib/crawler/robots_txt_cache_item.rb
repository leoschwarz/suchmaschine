module Crawler
  class RobotsTXTCacheItem
    include Common::Serializable
    
    fields :domain, :rules, :valid_until

    def save
      Crawler::Database.cache_set("robotstxt:#{self.domain}", self.serialize)
    end

    # Sucht nach einem robots.txt Cache-Eintrag für eine bestimmte Domain.
    def self.load(domain)
      item = self.deserialize(Crawler::Database.cache_get("robotstxt:#{domain}"))
      item = self.new({domain: domain}) if item.nil?
      item
    end

    def set_valid_for(seconds)
      if seconds == :default
        self.valid_until = Time.now.to_i + Config.robotstxt.cache_lifetime
      else
        self.valid_until = Time.now.to_i + seconds
      end
    end

    # Entweder :ok, :outdated oder :not_found
    def status
      if self.rules.nil?
        :not_found
      elsif self.valid_until < Time.now.to_i
        :outdated
      else
        :ok
      end
    end
  end
end
