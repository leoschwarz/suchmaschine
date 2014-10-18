#!/usr/bin/env ruby
# Programm um nach der Umbennung der Dokumente in zum Hash der URL die Metadaten zu korrigieren
# dh. konkret:
# Hinzufügen von: 
# - downloaded Attribut
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
puts "Totale Anzahl Dateien: #{metadata_hashes.size}\n"

def update_counter
  print "\r[#{$counter}/#{$total}]"
  $counter+=1
end

require 'lz4-ruby'
require 'oj'
def modify(path)
  data = Oj.load(LZ4.uncompress(File.read path))
  data = yield data
  File.write(LZ4.compress(Oj.dump(data)))
  update_counter
end

metadata_downloaded.each do |hash|
  modify("#{metadata_dir}#{hash}") do |data|
    data.delete(:document_hash)
    data[:downloaded] = true
    data
  end
end

metadata_not_downloaded.each do |hash|
  modify("#{document_dir}#{hash}") do |data|
    data.delete(:document_hash)
    data[:downloaded] = false
    data
  end
end

puts "\nFertig."
