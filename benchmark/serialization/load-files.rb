#!/usr/bin/env ruby
require_relative '../../lib/common/config'
require 'oj'; # TODO: entweder benchmark entfernen, oder updaten... require 'lz4-ruby'

n = 100

metadata_files = Dir[File.join(Config.paths.metadata, "*")].sample(n)
raise "Dateien nicht gefunden..." if metadata_files.size < n
metadata_files.each_with_index do |source_file, index|
  obj = Oj.load(LZ4.uncompress(File.read source_file))
  destination_file = File.join(File.dirname(__FILE__), "files", "#{index}.json")
  
  File.open(destination_file, "w") do |f|
    f.write(Oj.dump(obj))
  end
end
