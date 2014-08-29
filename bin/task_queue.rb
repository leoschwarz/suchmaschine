require 'socket'
require_relative '../lib/task_queue/task_queue.rb'
require_relative '../config/config.rb'

load_configuration(TaskQueue, "task_queue.yml")

module TaskQueue
  SERVER_PUT = "p"
  SERVER_GET = "g"
  
  def self.run
    queue = TaskQueue.new(config.save_to_disk, "db/task_queue.log")
    queue.load_from_disk
    
    socket = TCPServer.new 2051
    loop do
      client = socket.accept
      action = client.recv(1)
  
      if action == TaskQueue::SERVER_PUT
        url = client.recv(10000)
        queue.insert url
        client.close
      elsif action == TaskQueue::SERVER_GET
        client.write queue.fetch
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
