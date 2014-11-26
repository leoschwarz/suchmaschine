#!/usr/bin/env ruby
load( File.join(File.dirname(__FILE__), "..", "bin", "database") )

kb = Config.database.block_size.metadata
options = {}
options[:create_if_missing] = true
options[:compression]       = LevelDBNative::CompressionType::SnappyCompression
options[:block_size]        = kb * 1024
options[:write_buffer_size] = 16 * 1024*1024
data_store = LevelDBNative::DB.new(Config.paths.metadata, options)

domain_counts = Hash.new(0)
data_store.keys.each do |key|
  metadata = Database::Metadata.deserialize(data_store[key])
  domain   = (metadata.url).split("/")[0]
  @domain_counts[domain] += 1
end

total = 0
domain_counts.sort_by{|k,v| v}.reverse.each do |domain, value|
  puts "#{domain} => #{value}"
  total += value
end
puts "="*20
puts "TOTAL: #{total}"
