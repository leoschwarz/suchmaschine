require 'drb/drb'

module Common
  module DatabaseClient
    class Database
      def self.download_queue_insert(urls)
        self.run(:download_queue_insert, urls) unless urls.size == 0
      end

      def self.download_queue_fetch()
        URL.stored(self.run(:download_queue_fetch))
      end

      def self.index_queue_insert(doc_ids)
        self.run(:index_queue_insert, doc_ids) unless doc_ids.size == 0
      end

      def self.index_queue_fetch()
        self.run(:index_queue_fetch)
      end
      
      def self.index_get(word)
        r = self.run(:index_get, word)
        return [] if r.nil?
        r.split("\t")
      end

      def self.cache_set(key, value)
        self.run(:cache_set, key, value)
      end

      def self.cache_get(key)
        self.run(:cache_get, key)
      end

      def self.document_set(hash, document)
        self.run(:document_set, hash, document)
      end

      def self.document_get(hash)
        self.run(:document_get, hash)
      end

      def self.metadata_set(hash, metadata)
        self.run(:metadata_set, hash, metadata)
      end

      def self.metadata_get(hash)
        self.run(:metadata_get, hash)
      end
      
      def self.postings_get(word, block_number)
        self.run(:postings_get, word, block_number)
      end
      
      def self.postings_set(word, block_number, postings_binary)
        self.run(:postings_set, word, block_number, postings_binary)
      end
      
      def self.run(command, *params)
        server = DRbObject.new(nil, Config.database_connection)
        server.execute(command, params)
      end
    end
  end
end
