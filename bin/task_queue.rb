require 'socket'
require_relative '../lib/task_queue/task_queue.rb'


module TaskQueue
  SERVER_PUT = "p"
  SERVER_GET = "g"
end


queue = TaskQueue.new
socket = TCPServer.new 2051
loop do
  client = server.accept
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