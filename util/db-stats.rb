#!/usr/bin/env ruby
############################################################################################
# Dieses Programm gibt einige Statistiken über die Datenbank aus.                          #
# Um das Programm ausführen zu können, darf die Datenbank nicht von einem anderen Prozess  #
# verwendet werden. Die Ausführung kann unter Umständen einige Zeit in Anspruch nehmen.    #
############################################################################################
require_relative '../bin/database.rb'

# Datenbank laden.
db = Database::Backend.new

# Häufigste Domains ermitteln, um Zeit zu sparen wird hier lediglich die Verteilung von
# 100'000 zufällig ausgewählten Einträgen betrachtet.
domain_counts = Hash.new(0)
metadata_keys = db.datastore_keys(:metadata)
metadata_keys.sample(100_000).each do |key|
  metadata = Common::Database::Metadata.deserialize(db.datastore_get(:metadata, key))
  domain   = metadata.url.split("/")[0]
  domain_counts[domain] += 1
end

# Ausgabe der Domain-Verteilung:
puts "Häufigste Hosts im Korpus und ihr entsprechender Anteil:"
total = domain_counts.values.inject(:+)
domain_counts.sort_by{|_,count| count}.last(100).reverse.each do |domain, count|
  percent = count.to_f / total * 100
  puts "%.3f%% #{domain}" % percent
end

# Ausgabe der totalen Anzahl:
puts "==========================================="
puts "n(Dokumente) = #{metadata_keys.size}"
puts "n(Cache)     = #{db.datastore_keys(:cache).size}"
puts "==========================================="
