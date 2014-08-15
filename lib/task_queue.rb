module Crawler
  class TaskQueue
    attr_accessor :loader
    
    class Loader
      include EM::Deferrable
      attr_accessor :loading
      
      def initialize(task_queue)
        @task_queue = task_queue
        @loading = false
      end
      
      def run
        @loading = true
        Task.sample(Crawler.config.task_queue_size - @task_queue.length).callback{|tasks|
          @task_queue << tasks
          @loading = false
          succeed
        }.errback{|e|
          raise e
        }
      end
    end
    
    
    def initialize
      # Dieses Array beinhaltet die Elemente der Warteschlange. [0] = Ältestes, [n-1] = Neuestes
      @tasks = Array.new
      @loader = TaskQueue::Loader.new(self)
    end
    
    def pop
      @tasks.shift
    end
    
    def length
      @tasks.length
    end
    
    def push(item)
      if item.class == Array
        @tasks += item
      else
        @tasks << item
      end
    end
    
    def << (item)
      push(item)
    end
    
    def fetch
      Class.new{
        include EM::Deferrable
        
        def initialize(task_queue)
          if task_queue.length < Crawler.config.task_queue_size * Crawler.config.task_queue_threshold
            if task_queue.loader.loading
              if task_queue.length > 0
                # Es werden bereits neue Aufgaben geladen und es hat noch Aufgabe, also können wir bereits jetzt eine zurück geben.
                succeed task_queue.pop
              else
                # Es werden zwar neue Aufgaben geladen aber es hat noch nicht genug um sofort eine zurückzgeben.
                # Es muss also auf das Resultat des Ladevorganges gewartet werden.
                task_queue.loader.callback{
                  succeed task_queue.pop
                }
              end
            else
              task_queue.loader = TaskQueue::Loader.new(task_queue)
              task_queue.loader.run
              
              if task_queue.length > 0
                succeed task_queue.pop
              else
                task_queue.loader.callback{
                  succeed task_queue.pop
                }
              end
            end
          else
            # Es hat noch genügend Aufgaben in der Warteschlange.
            succeed task_queue.pop
          end
        end
      }.new(self)
    end
    
  end
end