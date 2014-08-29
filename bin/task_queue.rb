#!/usr/bin/env ruby

require 'bundler/setup'
require 'socket'
require 'rocksdb'
require_relative '../lib/task_queue/task_queue.rb'
require_relative '../config/config.rb'

load_configuration(TaskQueue, "task_queue.yml")

module TaskQueue
  module Actions
    INSERT_TASK = "p"
    FETCH_TASK = "g"
    GET_STATE = "s"
    SET_STATE = "S"
  end
  
  module States
    NEW = "0"
    SUCCESS = "1"
    FAILURE = "2"
  end
  
  def self.run
    queue = TaskQueue.new(config.save_to_disk, "db/task_queue.log")
    queue.load_from_disk
    
    db = RocksDB::DB.new config.rocksdb_path
    
    socket = TCPServer.new 2051
    loop do
      client = socket.accept
      action = client.recv(1)
  
      if action == Actions::INSERT_TASK
        url = client.recv(10000)
        queue.insert url
        db.put("url.state.#{url}", States::NEW)
        client.close
      elsif action == Actions::FETCH_TASK
        client.write queue.fetch
        client.close
      elsif action == Actions::GET_STATE
        url = client.recv(10000)
        client.write db.get("url.state.#{url}")
        client.close
      elsif action == Actions::SET_STATE
        state = client.recv(1)
        url   = client.recv(10000)
        db.put("url.state.#{url}", state)
        client.close
      else
        client.close
        raise "Unbekannte Aktion: #{action.inspect}"
      end
    end
  end
end

if __FILE__ == $0
  TaskQueue.run
end
