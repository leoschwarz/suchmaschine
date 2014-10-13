#!/usr/bin/env ruby
files = Dir["db/keyval/doc:*"]
puts "Anzahl Dateien: #{files.size}"

require 'oj'
require 'lz4-ruby'


queue = Queue.new
files.each_with_index{|file, index| queue << [file, index]}
files = nil

threads = 10.times.map do
  Thread.new do
    begin
      while (item = queue.pop(true))
        path,counter = item
	puts counter if counter % 1000 == 0
  	
        begin
          data = Oj.load(LZ4.uncompress(File.read(path)))
          data.delete(:html)
  
          File.open(path, "w") do |f|
            f.write(LZ4.compress(Oj.dump(data)))
          end        
        rescue
          File.unlink(path)
          puts "Datei gelöscht: #{path}"
        end
      end
    rescue ThreadError
    end
  end
end

threads.map(&:join)


