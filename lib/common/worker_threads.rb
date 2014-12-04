############################################################################################
# TODO

module Common
  class WorkerThreads
    # TODO: Alle stellen finden wo diese alte Instanzbasierte Variante verwendet wurde und diese entfernen, um danach hier aufräumen zu können.
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
        @threads.map(&:join)
      end
    end
    
    def self.run(thread_count, options={}, &block)
      options = {blocking: true}.merge(options)
      
      threads = thread_count.times.map do
        Thread.new do
          block.call
        end
      end
      
      if options[:blocking]
        threads.map(&:join)
      end
    end
  end
end
