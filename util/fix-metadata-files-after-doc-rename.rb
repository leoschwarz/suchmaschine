#!/usr/bin/env ruby
# Programm um nach der Umbennung der Dokumente in zum Hash der URL die Metadaten zu korrigieren
# dh. konkret:
# Hinzufügen von: 
# - downloaded Attribut
# - title Attribut (falls vorhanden)
# Entfernen von:
# - document_hash Attribut

metadata_dir = "/mnt/sdb/suchmaschine/metadata/"
document_dir = "/home/lightblaze/suchmaschine/db/doc/"

puts "Ordnerinhalte ermitteln..."
metadata_hashes = Dir[metadata_dir + "*"].map{|path| path.split("/")[-1]}
document_hashes = Dir[document_dir + "*"].map{|path| path.split("/")[-1]}
metadata_not_downloaded = metadata_hashes - document_hashes
metadata_downloaded     = document_hashes

$counter = 0
$total   = metadata_hashes.size

puts "Dateien umschreiben."
puts "Totale Anzahl Dateien: #{metadata_hashes.size}"
puts "Anzahl heruntergeladen: #{metadata_downloaded.size}"
puts "Anzahl nicht heruntergeladen: #{metadata_not_downloaded.size}\n"

def update_counter
  print "\r[#{$counter}/#{$total}]"
  $counter+=1
end

require 'lz4-ruby'
require 'oj'
def modify(path)
  begin
    data = Oj.load(LZ4.uncompress(File.read path))
    data = yield data
    File.open(path, "w") do |file|
      file.write(LZ4.compress(Oj.dump(data)))
    end
  rescue
    puts "E: Datei nicht gefunden: #{path}"
  end
  update_counter
end

queue = Queue.new
metadata_downloaded.each do |hash| 
  queue << hash
end
metadata_downloaded = nil

threads = 10.times.map do
  Thread.new do
    begin
      while (hash = queue.pop(true))
        modify("#{metadata_dir}#{hash}") do |data|
          data.delete(:document_hash)
          data[:downloaded] = true
          data[:title]      = Oj.load(LZ4.uncompress(File.read("#{document_dir}#{hash}")))[:title]
          data
        end
      end
    rescue ThreadError
    end
  end
end

threads.map(&:join)

queue = Queue.new

metadata_not_downloaded.each do |hash|
  queue << hash
end
queue = nil

threads = 10.times.map do
  Thread.new do
    begin
      while (hash = queue.pop(true))
        modify("#{metadata_dir}#{hash}") do |data|
          data.delete(:document_hash)
          data[:downloaded] = false
          data
        end
      end
    rescue ThreadError
    end
  end
end


puts "\nFertig."
