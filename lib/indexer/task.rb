module Indexer
  class Task
    def initialize(document_hash, text)
      @document_hash = document_hash
      @text          = text
    end
    
    def self.fetch
      docinfo_hash = Indexer::Database.index_queue_fetch
      docinfo      = Indexer::DocumentInfo.load(docinfo_hash)
      doc          = Indexer::Document.load(docinfo.document_hash)
      text         = doc.text
      self.new(doc.hash, text)
    end
    
    def run
      words = @text.gsub(/[^a-zA-ZäöüÄÖÜ]+/, " ").downcase.split(" ").uniq
      Indexer::Database.index_append(words.map{|word| [word, @document_hash]})
    end
  end
end
