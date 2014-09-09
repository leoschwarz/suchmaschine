module Crawler
  class TaskQueueConnection < EventMachine::Connection
    def initialize(parent, send_data)
      @parent = parent
      @received_data = ""
      @send_data = send_data
    end
    
    def post_init
      send_data(@send_data)
    end
    
    def receive_data(chunk)
      @received_data << chunk
    end
    
    def unbind
      if @received_data.length > 0
        @parent.succeed(@received_data.split("\t"))
      else
        @parent.succeed
      end
    end
  end
  
  class TaskQueue
    include EM::Deferrable
    
    def initialize(send_data)
      EM.connect("127.0.0.1", 2051, TaskQueueConnection, self, send_data)
    end
    
    def self.fetch_tasks(n=1)
      self.new("TASK_FETCH\t#{n}\n")
    end
    
    def self.insert_tasks(urls)
      self.new("TASK_INSERT\t#{urls.join("\t")}\n")
    end
    
    def self.get_states(urls)
      self.new("STATE_GET\t#{urls.join("\t")}\n")
    end
    
    # pairs: Hash mit Schlüssel = URL, Wert = Status
    def self.set_states(pairs)
      data = pairs.to_a.join("\t")
      self.new("STATE_SET\t#{data}\n")
    end
  end
end