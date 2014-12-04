#!/usr/bin/env ruby
############################################################################################
# Dieses Skript löscht die gesammte Datenbank und sollte nur dann verwendet werden, wenn   #
# wirklich alle Daten der Suchmaschine gelöscht werden sollten.                            #
############################################################################################
require_relative '../lib/common/config.rb'
require_relative '../lib/common/index_file.rb'

print "Warnung: Dieses Skript wird alle Daten der Datenbank löschen.\n"
print "Wirklich fortfahren? (Ich will alles löschen/[Nein]): "
verification = gets.strip
if verification != "Ich will alles löschen"
  puts "Es wurde nichts gelöscht."
  Kernel.exit
end

dirs = [
  Config.paths.cache,
  Config.paths.search_cache,
  Config.paths.document,
  Config.paths.download_queue,
  Config.paths.index_queue,
  Config.paths.metadata
]

dirs.each do |dir|
  Dir["#{dir}/*"].each do |file|
    File.unlink(file)
  end
  puts "Verzeichnis #{dir} geleert."
end

# Index löschen:
index_file = Common::IndexFile.new(Config.paths.index)
index_file.delete
puts "Indexdatei gelöscht."

puts "Alles gelöscht."
