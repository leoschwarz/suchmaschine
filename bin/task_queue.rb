#!/usr/bin/env ruby

require 'bundler/setup'
require 'socket'
require 'rocksdb'
require_relative '../lib/task_queue/task_queue.rb'
require_relative '../config/config.rb'

load_configuration(TaskQueue, "task_queue.yml")

# API Dokumentation :: 
# 
# TASK_INSERT\tURL1[\tURL2\t...]\n
# TASK_FETCH\tN\n
# STATE_GET\tURL1[\tURL2\t...]\n
# STATE_SET\tURL1[\tSTATE1\t...]\n

module TaskQueue
  module States
    NEW = "0"
    SUCCESS = "1"
    FAILURE = "2"
  end
  
  def self.run
    db = RocksDB::DB.new config.rocksdb_path
    
    puts "Die Warteschlange wird geladen und optimiert."
    puts "Das optimieren, könnte einen Augenblick in Anspruch nehmen."
    queue = TaskQueue.new(config.save_to_disk, "db/task_queue.log")
    queue.load_from_disk
    puts "Laden der Warteschlange beendet. Es befinden sich #{queue.size} Einträge im RAM."
    puts "Der Server läuft nun auf Port 2051."
    
    socket = TCPServer.new 2051
    
    loop do
      client = socket.accept
      buffer = ""
      while buffer[-1] != "\n"
        buffer << client.recv(5000)
      end
      
      request = buffer[0...-1].split("\t")
      response = case
        when request[0] == "TASK_INSERT"
          request[1..-1].each{|url| queue.insert(url) }
          String.new
        when request[0] == "TASK_FETCH"
          num = request[1].to_i
          urls = []
          num.times{ urls << queue.fetch }
          urls.join("\t")
        when request[0] == "STATE_GET"
          urls = request[1..-1]
          urls.map{|url| db.get("url.state.#{url}")}.join("\t")
        when request[0] == "STATE_SET"
          pairs = (request.size-1) / 2
          (0...pairs).each do |i|
            db.put("url.state.#{request[2*i+1]}", request[2*i+2])
          end
      end
      
      client.write response
      client.close
    end
  end
end

if __FILE__ == $0
  TaskQueue.run
end
