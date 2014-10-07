require 'singleton'

module Database
  class Index
    include Singleton
    
    def initialize
      # TODO LRU-Implementierung verwenden (FIFO macht hier wenig Sinn; Platzhalter)
      @cache = Common::RAMCacheFIFO.new(1000)
    end
    
    # Fügt docinfo_id zu einem existierendem Index File hinzu oder erstellt ein neues.
    def append(word, doc_id)
      index_item = @cache[word]
      if index_item.nil?
        index_item = IndexItem.new(word)
        @cache[word] = index_item
      end
      index_item.append(doc_id)
    end
    
    def save_everything
      @cache.remove_all
    end
  end
  
  class IndexItem
    def initialize(word)
      path  = File.join(Database.config.index.directory, "word:#{word}")
      @file = File.open(path, "a")
    end
    
    def append(doc_id)
      @file.puts doc_id
    end
    
    # Wenn das Element aus dem Cache gelagert wird, muss die Datei geschlossen werden.
    def removed_from_cache
      @file.close
    end
  end
end