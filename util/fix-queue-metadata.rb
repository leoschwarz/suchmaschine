#!/usr/bin/env ruby
############################################################################################
# Durch einen Fehler bei der Handhabung der Warteschlangen ist es möglich, dass die        #
# entsprechenden Metadaten nicht gespeichert werden, und es nötig wird diese zu            #
# rekonstruieren. Dieses Skript ermöglicht die Wiederherstellung der Metadaten einer       #
# BetterQueue-Warteschlange. Dazu müssen aber die anderen Inhalte im Verzeichnis der       #
# Warteschlange unbeschädigt vorliegen.                                                    #
############################################################################################
require_relative '../lib/common/common.rb'
require_relative '../lib/database/better_queue_metadata.rb'

# Pfad des Warteschlange-Verzeichnis ermitteln.
print "Bitte den Pfad des Warteschlange-Verzeichnis angeben:"
path = gets.strip

# Überprüfen ob Verzeichnis existiert.
if !Dir.exist?(path)
  puts "Das Verzeichnis existiert leider nicht."
  Kernel.exit
end

# Überprüfen ob Metadaten bereits existieren.
metadata_path = File.join(path, "metadata")
if File.exist?(metadata_path)
  puts "Es existiert bereits eine Metadaten-Datei."
  print "Datei löschen? Ja/[Nein] "
  answer = gets.strip
  unless answer.downcase == "ja"
    Kernel.exit
  end
  File.unlink(metadata_path)
end

# Zeilenanzahl der jeweiligen Stapel ermitteln.
metadata = Database::BetterQueueMetadata.new
metadata.path = metadata_path
metadata.batches = {}
files = Dir[File.join(path, "*")]
files.each do |file|
  lines = File.read(file).lines.count
  metadata.batches[File.basename(file)] = [lines]
end

# Stapel-Zähler rekonstruieren.
metadata.batch_counter = files.map{|filename| File.basename(filename).to_i}.max

# Resultate speichern.
metadata.save
puts "Metadaten der Warteschlange erfolgreich rekonstruiert."
