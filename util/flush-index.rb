#!/usr/bin/env ruby
# Dieses Skript löscht den Index der Suchmaschine und befüllt die INDEX_QUEUE erneut.
require './bin/indexer.rb'

INDEX_DIRECTORY       = "/mnt/sdb/suchmaschine/index/"
INDEX_QUEUE_DIRECTORY = File.join(File.dirname(__FILE__), "../db/index/")
DOCINFO_DIRECTORY     = "/mnt/sdb/suchmaschine/docinfo/"
raise "Dieses Programm muss mit Zugriff auf das INDEX-Verzeichniss ausgeführt werden" unless Dir.exist? INDEX_DIRECTORY
raise "Dieses Programm muss mit Zugriff auf das INDEX_QUEUE-Verzeichniss ausgeführt werden" unless Dir.exist? INDEX_QUEUE_DIRECTORY
raise "Dieses Programm muss mit Zugriff auf das DOCINFO-Verzeichniss ausgeführt werden" unless Dir.exist? DOCINFO_DIRECTORY


index_files = Dir["#{INDEX_DIRECTORY}/*"]
index_queue_files = Dir["#{INDEX_QUEUE_DIRECTORY}/*"]
index_files_count = index_files.size
index_queue_files_count = index_queue_files.size

puts "Warnung, dieses Skript wird #{index_files.size} INDEX-Einträge unwiederbringlich löschen."
puts "Die Datenbank DARF NICHT laufen solange dieses Skript ausgeführt wird."
print "Um fortzufahren, bitte 'index löschen' eintippen: "
input = gets.strip

if input != "index löschen"
  puts "Es wurde nichts gelöscht."
  exit
end

puts "Löschvorgang begonnen..."
puts "Löschen aller Dateien im INDEX-Verzeichniss:"
counter = 0
index_files.each do |index_file|
  File.unlink index_file
  counter += 1
  print "\r[#{counter}/#{index_files_count}] gelöscht." if counter % 1000 == 0
end
print "\n"
puts "Löschen aller Dateien im INDEX-Verzeichniss erfolgreich."

puts "Löschen der alten INDEX_QUEUE begonnen..."
index_queue_files.each do |file|
  File.unlink(file)
end
puts "Löschen der alten INDEX_QUEUE erfolgreich."

docinfo_ids = Dir["#{DOCINFO_DIRECTORY}/*"].map{|path| path.split("/")[-1]}
docinfo_ids_count = docinfo_ids.size
puts "Bitte Datenbank jetzt starten und dann Enter drücken..."
gets

puts "Befüllen der INDEX_QUEUE begonnen..."
counter = 0
docinfo_ids.each_slice(200) do |ids|
  Indexer::Database.index_queue_insert(ids)
  counter += 200
  print "\r[#{counter}/#{docinfo_ids_count}] eingefügt." if counter % 1000 == 0
end
print "\n"

puts "Befüllen beendet. Jetzt können Clients wie gewohnt verbunden werden..."
