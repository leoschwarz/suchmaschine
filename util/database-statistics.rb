#!/usr/bin/env ruby
# Gibt Auskunft über die gespeicherten Webseiten

require_relative '../bin/database.rb'
require 'oj'
require 'lz4-ruby'

$data_dir = Database.config.ssd.path

puts "CACHE EINTRÄGE   : #{Dir["#{$data_dir}/cache/*"].size}"
docinfo_paths = Dir["#{$data_dir}/docinfo/*"]
puts "DOCINFO EINTRÄGE : #{docinfo_paths.size}"

domain_counts = {}
docinfo_paths.each do |path|
  url = Oj.load(LZ4::uncompress(File.read(path)))[:url]
  match = /^([a-zA-Z0-9\.-]+)/.match(url)
  if not match.nil?
    domain_name = match[1].downcase
    if domain_counts.has_key? domain_name
      domain_counts[domain_name] += 1
    else
      domain_counts[domain_name]  = 1
    end
  end
end
puts "DOMAIN HÄUFIGKEIT (top 100):"
puts domain_counts.sort_by{|url, c| c}.reverse[0...100].map{|row| row.join(" => ")}

index_files = Dir["#{$data_dir}/index/word:*"]
puts "INDEX EINTRÄGE   : #{index_files.size}"
index_counts = {}
index_files.each do |path|
  word = path.split(":")[1]
  index_counts[word] = File.read(path).lines.size
end
puts "TOP 100 INDEX:"
puts index_counts.sort_by{|word, c| c}.reverse[0...100].map{|row| row.join(" =>")}
