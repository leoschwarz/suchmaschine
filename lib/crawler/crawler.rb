# TODO aufräumen

module Crawler
end

Common::load_configuration(Crawler, "crawler.yml")

module Crawler
  include Common::DatabaseClient
  Database.configure(self.config.database.host, self.config.database.port)
end

# Alle Dateien im Verzeichnis laden 
Dir[File.join(File.dirname(__FILE__), './*.rb')].each {|file| require file }
