module Common
  class ProgressLogger
    def initialize(variables=OrderedHash.new, logger=nil)
      @default = variables
      
      @logger = logger
      if @logger.nil?
        @logger = Logger.new
        @logger.add_output($stdout, Logger::INFO)
      end
      
      @stopped = false
    end
    
    def reset
      @start_time = Time.now
      @variables  = @default.clone
      @stopped    = false
    end
    
    # Startet einen neuen Thread
    def start_display(interval)
      @display_settings = {interval: interval}
      self.reset
      
      @display_thread = Thread.new do
        print_header        
        while !@stopped
          print_values unless @stopped
          sleep interval
        end
      end
    end
    
    def [](key)
      value = @variables[key]
      if value.class == Proc
        value.call(self)
      else
        value
      end
    end
    
    def []=(key, value)
      @variables[key] = value
    end
    
    def pairs
      @variables.keys.map{|key| [key, self[key]]}
    end
    
    def elapsed_time
      (Time.now - @start_time).round(2)
    end
    
    def stop_display
      @stopped = true
      @display_thread.kill
    end
    
    def restart_display
      stop_display
      start_display(@display_settings[:interval], @display_settings[:start_thread])
    end
    
    private
    def print_header
      @logger.log_info pairs.map{|k, v| @logger._label(k)}.join("\t")
    end
    
    def print_values
      @logger.log_info pairs.map{|k, v| v}.join("\t")
    end
  end
end
