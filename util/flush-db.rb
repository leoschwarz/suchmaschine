#!/usr/bin/env ruby
require_relative '../lib/common/config'

print "Sicher? (Ich will alles löschen/[Nein]): "
verification = gets.strip
if verification != "Ich will alles löschen"
  puts "Abgebrochen."
  Kernel.exit
end

dirs = [
  Config.paths.cache,
  Config.paths.search_cache,
  Config.paths.document,
  Config.paths.download_queue,
  Config.paths.index_queue,
  Config.paths.postings_block,
  Config.paths.postings_metadata,
  Config.paths.metadata
]

dirs.each do |dir|
  Dir["#{dir}/*"].each do |file|
    File.unlink(file)
  end
  puts "Verzeichnis #{dir} geleert."
end

puts "Alles gelöscht."
