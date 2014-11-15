module Indexer
  class IndexingCacheItem
    attr_accessor :entries
    
    def initialize(cache, word)
      @cache = cache
      @word  = word
      @entries = []
    end
    
    def << (row)
      if !@cache.register_row_append
        @cache[@word] << row
        return
      end
      
      @entries << row
    end
  end
  
  class IndexingCache
    MAX_SIZE = 5_000_000
    
    def initialize
      @size = 0
      @data = {}
      @words = {}
      @writing = false
      
      @data_mutex = Mutex.new
    end
    
    def [](key)
      @data_mutex.synchronize do
        if @data.has_key?(key)
          return @data[key]
        else
          @words[key] = nil
          return @data[key] = IndexingCacheItem.new(self, key)
        end
      end
    end
    
    def words
      @words.keys
    end
    
    # true falls erfolgreich, false falls nicht (bereits voll...)
    def register_row_append
      @size += Indexer::PostingsBlock::ROW_SIZE
      if @size > MAX_SIZE
        write_to_disk
        return false
      else
        return true
      end
    end
    
    def write_to_disk
      if @writer_thread.nil? || !@writer_thread.alive?
        @writer_thread = Thread.new do
          # Wertepaare in eine Warteschlange laden...
          queue = Thread::Queue.new
          @data_mutex.synchronize do
            @data.each_pair{|word, item| queue << [word, item.entries]}
            @data.clear
          end
          
          Common::WorkerThreads.new(10).run(true) do
            begin
              while (pair = queue.pop(true))
                # TODO: Diese Übertragung hier ist noch immer viel zu langsam...
                #       Wahrscheinlich sollte man mehrere Anfragen bündeln und dann diese die Datenbank in einem
                #       Durchgang schreiben lassen...
                
                word, entries = pair
                # TODO: Die Möglichkeit, dass hier mehr als ein Block entstehen können, was dem 
                #       Index Sortierer Probleme machen würde, wird zwar mit der Momenanten Konfiguration
                #       nicht eintreten, soll aber dennoch nicht vernachlässigt werden, denn es
                #       könnte unter Umständen dennoch zu Problemen kommen.
                #       (Beispielsweise wenn der Indexierer mehrfach gestartet wird, aber nicht bis zum
                #        sortieren gelangt...)
                postings = Indexer::Postings.new(word, temporary: false, load: true)
                postings.add_rows(entries)
                postings.save
              end
            rescue ThreadError
              # Dies tritt ein, wenn die Warteschlange abgearbeitet wurde.
            end
          end
          
          @size = 0
        end
      end
      
      @writer_thread.join
    end
  end
end
