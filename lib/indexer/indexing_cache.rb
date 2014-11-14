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
        # TODO: Hier nur einen Thread zu verwenden, d.h. jeden Eintrag einen nach dem anderen zur Datenbank zu übertragen
        # ist extrem ineffizient, dies muss dringend verbessert werden!
        @writer_thread = Thread.new do
          # TODO: Fortschrittanzeige?
          started = Time.now
          puts "Mit dem Niederschreiben des IndexingCache begonnen..."
          
          @data_mutex.synchronize do
            @data.each_pair do |word, item|
              postings = Indexer::Postings.new(word, temporary: false, load: true)
              postings.add_rows(item.entries)
              postings.save
            end
            @data.clear
          end
          
          @size = 0
      
          puts "IndexingCache in #{(Time.now - started).round(1)}s abgeschlossen."
        end
      end
      
      @writer_thread.join
    end
  end
end
