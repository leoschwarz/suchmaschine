# Alle Dateien im Verzeichnis laden
Dir[File.join(File.dirname(__FILE__), './*.rb')].each {|file| require file }

require_relative './database_client/database_client.rb'

Common::load_configuration(Common, "common.yml")
