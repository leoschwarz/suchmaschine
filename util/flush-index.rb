#!/usr/bin/env ruby
# Dieses Skript löscht den Index der Suchmaschine und befüllt die INDEX_QUEUE erneut.
load './bin/database'
load './bin/indexer'

print "Warnung, dieses Skript wird alle Postings (und zugehörige Metadaten) unwiederbringlich löschen.\n"
print "Um fortzufahren, bitte 'index löschen' eintippen: "
input = gets.strip
if input != "index löschen"
  puts "Es wurde nichts gelöscht."
  Kernel.exit
end

begin
  db = Database::Backend.new
rescue => e
  raise "Um den Indexierer ausführen zu können, darf die Datenbank nicht von einem anderen Prozess verwendet werden."
end

puts "Löschvorgang begonnen..."
puts "Löschen aller Index-Dateien..."

File.unlink(Config.paths.index)
Dir[File.join(File.dirname(__FILE__), "..", "tmp", "index", "*")].each{|file| File.unlink(file)}
Dir[Config.paths.index_queue+"*"].each{|file| File.unlink(file)}

puts "Alte Dateien gelöscht, beginne die neue Warteschlange zu befüllen..."

puts "Befüllen der Index-Warteschlange begonnen..."
keys = db.datastore_keys(:metadata)
total = keys.size
counter = 0
keys.each do |key|
  db.queue_insert(:index, key)
  counter += 1
  print "\r[#{counter}/#{total}] eingefügt." if counter % 100 == 0
end

db.save

puts "\rBefüllen beendet.                      "
