#!/usr/bin/env ruby
# Durch einen Fehler und ein schlechtes Programm ist es dazu gekommen, dass die Metadaten einer Warteschlange nicht gespeichert wurden?
# Kein Problem, mit diesem kleinen Skript kann man diese wieder regenerieren...
# TODO: Eventuell dies später direkt in die Warteschlange integriereren...
require_relative '../lib/common/common.rb'
require_relative '../lib/database/better_queue_metadata.rb'

# Pfad erhalten
print "Bitte gibt den Dateipfad des Ordners der für die Speicherung der Warteschlange verwendet wird an: "
path = gets.strip

# Überprüfen ob Verzeichnis existiert
if ! Dir.exist?(path)
  puts "Das Verzeichnis existiert leider nicht..."
  Kernel.exit
end

# Überprüfen ob Metadaten bereits existieren:
metadata_path = File.join(path, "metadata")
if File.exist?(metadata_path)
  puts "Es existiert eine metadata-Datei."
  print "Datei löschen? Ja/[Nein] "
  answer = gets.strip
  unless answer.downcase == "ja"
    Kernel.exit
  end
  File.unlink(metadata_path)
end

# Zeilenanzahl rekonstruieren...
metadata = Database::BetterQueueMetadata.new
metadata.path = metadata_path
metadata.batches = {}
files = Dir[File.join(path, "*")]
files.each do |file|
  lines = File.read(file).lines.count
  metadata.batches[File.basename(file)] = [lines]
end

# Counter rekonstruieren
metadata.batch_counter = files.map{|filename| File.basename(filename).to_i}.max

# Resultate speichern.
metadata.save
puts "Metadaten der Warteschlange erfolgreich rekonstruiert."
