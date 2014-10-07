module Crawler
  include Common::DatabaseClient
end

Common::load_configuration(Crawler, "crawler.yml")

# Alle Dateien im Verzeichnis laden 
Dir[File.join(File.dirname(__FILE__), './*.rb')].each {|file| require file }
