module Indexer
  class IndexingCacheFullError < StandardError
  end
  
  class IndexingCacheItem
    attr_accessor :entries
    
    def initialize(cache, word)
      @cache = cache
      @word  = word
      @entries = []
    end
    
    def << (row)
      begin
        @cache.register_row_append
      rescue IndexingCacheFullError
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
      @writing = false
      
      @data_mutex = Mutex.new
    end
    
    def [](key)
      @data_mutex.synchronize do
        if @data.has_key?(key)
          return @data[key]
        else
          return @data[key] = IndexingCacheItem.new(self, key)
        end
      end
    end
    
    def register_row_append
      @size += Common::PostingsFile::ROW_SIZE
      if @size > MAX_SIZE
        write_to_disk
        raise IndexingCacheFullError
      end
    end
    
    def write_to_disk
      if @writer_thread.nil? || ! @writer_thread.alive?
        @writer_thread = Thread.new do
          started = Time.now
          puts "Mit dem Niederschreiben des IndexingCache begonnen..."
      
          @data.each_pair do |key, item|
            postings_tmp(key).write_entries(item.entries)
          end
          @data.clear
          @size = 0
      
          puts "IndexingCache in #{(Time.now - started).round(1)}s abgeschlossen."
        end
      end
      
      @writer_thread.join
    end
    
    def self.instance
      @@instance ||= IndexingCache.new
    end
    
    def self.[](key)
      self.instance[key]
    end
    
    def self.write_to_disk
      self.instance.write_to_disk
    end
    
    private
    def postings_tmp(word)
      Common::PostingsFile.new(File.join(Config.paths.index_tmp, "word:#{word}"), true)
    end
  end
end
