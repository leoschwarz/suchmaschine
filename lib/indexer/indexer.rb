module Indexer
  include Common::Database
end

# Alle Dateien im Verzeichnis laden
Dir[File.join(File.dirname(__FILE__), './*.rb')].each {|file| require file }
