#!/usr/bin/env ruby
files = Dir["db/keyval/*"]
puts "Anzahl Dateien: #{files.size}"

require 'oj'
require 'lz4-ruby'
require 'digest/md5'
require 'fileutils'

queue = Queue.new
files.each_with_index{|file, index| queue << [file, index]}
files = nil

threads = 10.times.map do
  Thread.new do
    begin
      while (item = queue.pop(true))
        path,counter = item
	puts counter if counter % 1000 == 0
  	
        raw = File.read(path)
        data = Oj.load(LZ4.uncompress(raw))
#	  File.unlink(path)
        metadata = Digest::MD5.hexdigest(data[:url])
  
	FileUtils.mv(path, "db/doc/#{metadata}")

#        File.open("db/doc/#{metadata}", "w") do |f|
#          f.write(raw)
#        end
      end
    rescue ThreadError
    end
  end
end

threads.map(&:join)
