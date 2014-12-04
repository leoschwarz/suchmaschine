############################################################################################
# Das WorkerThreads Modul ist ein kleiner Helfer um das Abarbeiten von vielen Aufgaben in  #
# vielen Threads übersichtlich zu ermöglichen.                                             #
############################################################################################
module Common
  module WorkerThreads
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
