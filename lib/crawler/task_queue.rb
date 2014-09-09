require 'socket'

module Crawler
  class TaskQueue
    def run(query)
      connection = TCPSocket.new("127.0.0.1", 2051)
      connection.send(query, 0)
      response = connection.recv(100000)
      connection.close
      response.split("\t")
    end
    
    def self.fetch_raw_tasks(n=1)
      self.new.run("TASK_FETCH\t#{n}\n")
    end
    
    def self.fetch_task
      url = self.fetch_raw_tasks(1).first
      Crawler::Task.new(url)
    end
    
    def self.insert_tasks(urls)
      self.new.run("TASK_INSERT\t#{urls.join("\t")}\n")
    end
    
    def self.get_states(urls)
      self.new.run("STATE_GET\t#{urls.join("\t")}\n")
    end
    
    # pairs: Hash mit Schlüssel = URL, Wert = Status
    def self.set_states(pairs)
      data = pairs.to_a.join("\t")
      self.new.run("STATE_SET\t#{data}\n")
    end
  end
end