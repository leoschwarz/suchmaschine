require 'configatron/core'

module Crawler
  @@config = nil
  def self.config
    if @@config.nil?
      @@config = Configatron::RootStore.new
    end
    @@config
  end
  
  # Benutzeragent der bei Requests mitgesendet wird, und nach dem in robots.txt Dateien gesucht wird.
  config.user_agent = "lightblaze"
  # Timeout von robots.txt requests in Sekunden
  config.robots_txt.timeout = 0.5
  # Maximales Alter von gecachten robots.txt Regeln in Sekunden
  config.robots_txt.cache_duration = 24 * 60*60
  
end