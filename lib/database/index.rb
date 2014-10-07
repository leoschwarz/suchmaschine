require 'singleton'

module Database
  class Index
    include Singleton
    
    def initialize
      @index_items = Common::RAMCacheLRU.new(1000)
    end
    
    # Fügt docinfo_id zu einem existierendem Index File hinzu oder erstellt ein neues.
    def append(word, doc_id)
      @index_items[word] ||= IndexItem.new(word)
      @index_items[word].append(doc_id)
    end
    
    def save_everything
      @index_items.remove_all
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