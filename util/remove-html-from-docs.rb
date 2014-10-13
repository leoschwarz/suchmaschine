#!/usr/bin/env ruby
files = Dir["db/keyval/doc:*"]
puts "Anzahl Dateien: #{files.size}"

require 'oj'
require 'lz4-ruby'

files.each_with_index do |path, counter|
  puts counter if counter % 1000 == 0
  
  data = Oj.load(LZ4.uncompress(File.read(path)))
  data.delete(:html)
  
  File.open(path, "w") do |f|
    f.write(LZ4.compress(Oj.dump(data)))
  end
end