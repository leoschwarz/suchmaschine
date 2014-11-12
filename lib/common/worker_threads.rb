module Common
  class WorkerThreads
    def initialize(thread_number)
      @thread_number = thread_number
    end
    
    def run(blocking=true, &block)
      @threads = @thread_number.times.map do
        Thread.new do
          block.call
        end
      end
      
      if blocking
        @threads.map{|thread| thread.join}
      end
    end
  end
end
