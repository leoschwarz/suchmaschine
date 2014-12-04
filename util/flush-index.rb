#!/usr/bin/env ruby
############################################################################################
# Dieses Skript löscht den Index der Suchmaschine und befüllt die Index Warteschlange      #
# erneut, indem alle heruntergeladenen Dokumente in die Warteschlange eingetragen werden.  #
#                                                                                          #
# Dieses Programm führt die Datenbankoperationen über direkt auf der Datenbank durch, was  #
# bedeutet, dass die Datenbank nicht bereits von einem anderen Prozess verwendet werden    #
# darf.                                                                                    #
############################################################################################
require_relative '../bin/database.rb'
require_relative '../bin/indexer.rb'

print "Warnung: Dieses Skript wird den gesammten bereits bestehenden Index löschen.\n"
print "Wirklich fortfahren? (Ich will den Index löschen/[Nein]): "
verification = gets.strip
if verification != "Ich will den Index löschen"
  puts "Es wurde nichts gelöscht."
  Kernel.exit
end

puts "Der Löschvorgang wird begonnen."
puts "Löschung aller Index-Dateien begonnen."

allpaths = [
  Config.paths.index,
  Config.paths.index_tmp+"*",
  Config.paths.index_queue+"*"
]
allpaths.each do |paths|
  Dir[paths].each do |path|
    File.unlink(path) if File.exist?(path)
  end
end
Dir.delete(Config.paths.index_tmp) if Dir.exist?(Config.paths.index_tmp)

puts "Löschung aller Index-Dateien abgeschlossen."
puts "Befüllung der Index Warteschlange begonnen."

begin
  db = Database::Backend.new
rescue => e
  puts "Die Datenbank darf nicht von einem anderen Prozess verwendet werden."
  puts "Befüllung der Datenbank fehlgeschlagen."
  raise e
end

keys = db.datastore_keys(:metadata)
total = keys.size
counter = 0
keys.each do |key|
  db.queue_insert(:index, key)
  counter += 1
  print "\r[#{counter}/#{total}] eingefügt." if counter % 100 == 0
end
db.save

puts "\rBefüllung der Index Warteschlange abgeschlossen."
puts "Der Index wurde erfolgreich gelöscht."
