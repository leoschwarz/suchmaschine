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
        @parent.succeed(Crawler::Task.new(@received_data))
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
    
    def self.fetch
      self.new("g")
    end
    
    def self.insert(url)
      self.new("p"+url)
    end
    
    def self.get_state(url)
      self.new("s"+url)
    end
    
    def self.set_state(url, state)
      if state.length > 1
        raise "'state' muss ein String mit der Länge 1 sein."
      end
      self.new("S"+state+url)
    end
  end
end