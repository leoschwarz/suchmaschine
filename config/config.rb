require 'ostruct'

module Crawler
  class << self
    attr_accessor :config
  end
  self.config = OpenStruct.new
  self.config.robotstxt = OpenStruct.new
  
  
  # Anzahl Aufgaben die in der Memory-Warteschleife enthalten sein sollen
  config.task_queue_size = 100
  # Anzahl paralleler Downloads
  config.parallel_tasks = 10
  # Benutzeragent der bei Requests mitgesendet wird, und nach dem in robots.txt Dateien gesucht wird.
  config.user_agent = "lightblaze"
  # Timeout von robots.txt requests in Sekunden
  config.robotstxt.timeout = 10
  # Verwendung von Cache für robots.txt
  config.robotstxt.use_cache = true
  # Maximales Alter von gecachten robots.txt Regeln in Sekunden
  config.robotstxt.cache_lifetime = 24 * 60*60
end