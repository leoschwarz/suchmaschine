# TODO: Wenn Zeit, noch etwas aufräumen.

module Common
  class ThreadPool
    def initialize(threads_count, &block)
      @threads_count = threads_count
      @block = block
    end
    
    def run(wait)
      @threads_count.times do
        Thread.new do
          @block.call
        end
      end
    end
    
    def self.run(threads_count, wait, &block)
      ThreadPool.new(threads_count, block).run(wait)
    end
  end
  
  class ThreadWorkerPool
    def initialize(threads_count, &block)
      @threads_count = threads_count
      @block = block
    end
    
    def run(source, wait)
      if source.class == Array || source.class == Thread::Queue
        if source.class == Array
          queue = Thread::Queue.new
          source.each{ |item| queue << item }
        else
          queue = source
        end
        
        threads = @threads_count.times.map do
          Thread.new do
            begin
              while (item = queue.pop(true))
                @block.call(item)
              end
            rescue ThreadError
            end
          end
        end
        
        threads.map{|t| t.join} if wait
      elsif source.class == Proc
        threads = @threads_count.times.map do
          Thread.new do
            while (item = source.call)
              @block.call(item)
            end
          end
        end
        
        threads.map{|t| t.join} if wait
      else
        raise "Falscher Typ für 'source': #{source.class}"
      end
    end
  end
end
