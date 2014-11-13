#!/usr/bin/env ruby
# Dieses Skript löscht den Index der Suchmaschine und befüllt die INDEX_QUEUE erneut.
load './bin/database'
load './bin/indexer'

options = {block_size: 8* 1024*1024, write_buffer_size: 16 *1024*1024, compression: LevelDBNative::CompressionType::SnappyCompression}

# aus: lib/database/server.rb
db_options = {}
{document: 256, 
 metadata: 8,
    cache: 8,
 postings: 256,
 postings_metadata: 8,
 postings_temporary: 8,
 postings_metadata_temporary: 8}.each_pair do |name, kb|
  options = {}
  options[:create_if_missing] = true
  options[:compression]       = LevelDBNative::CompressionType::SnappyCompression
  options[:block_size]        = kb * 1024
  options[:write_buffer_size] = 16 * 1024*1024
  db_options[name] = options # = LevelDBNative::DB.new(Config.paths[name], options)
end



print "Warnung, dieses Skript wird alle Postings (und zugehörige Metadaten) unwiederbringlich löschen.\n"
print "Um fortzufahren, bitte 'index löschen' eintippen: "
input = gets.strip
if input != "index löschen"
  puts "Es wurde nichts gelöscht."
  Kernel.exit
end

puts "Löschvorgang begonnen..."
puts "Löschen aller Index-Dateien..."
files  = Dir[Config.paths.postings + "*"]
files += Dir[Config.paths.postings_metadata + "*"]
files += Dir[Config.paths.postings_temporary + "*"]
files += Dir[Config.paths.postings_metadata_temporary + "*"]

total = files.count

counter = 0
files.each do |file|
  File.unlink file
  counter += 1
  print "\r[#{counter}/#{total}] gelöscht." if counter % 100 == 0
end
puts "\rLöschen aller Index Dateien erfolgreich."

puts "Löschen der alten INDEX_QUEUE begonnen..."
Dir[Config.paths.index_queue + "*"].each do |file|
  File.unlink(file)
end
puts "Löschen der alten INDEX_QUEUE erfolgreich."

puts "Befüllen der INDEX_QUEUE begonnen..."
ids = LevelDBNative::DB.new(Config.paths.metadata, db_options[:metadata]).keys
counter = 0
total = ids.count
queue = Database::BetterQueue.new(Config.paths.index_queue)
ids.each do |id|
  queue.insert(id)
  counter += 1
  print "\r[#{counter}/#{total}] eingefügt." if counter % 100 == 0
end

queue.save
puts "\rBefüllen beendet."
