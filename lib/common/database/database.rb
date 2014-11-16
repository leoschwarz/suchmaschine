require_relative './database.rb'
require_relative './document.rb'
require_relative './metadata.rb'
require_relative './postings.rb'
require_relative './postings_block.rb'
require_relative './postings_metadata.rb'

require 'drb/drb'

module Common
  module Database
    class Database
      def self.download_queue_insert(urls)
        self.run(:download_queue, :insert, urls) unless urls.size == 0
      end

      def self.download_queue_fetch()
        URL.stored(self.run(:download_queue, :fetch))
      end

      def self.index_queue_insert(ids)
        self.run(:index_queue, :insert, ids) unless ids.size == 0
      end

      def self.index_queue_fetch()
        self.run(:index_queue, :fetch)
      end
      
      def self.cache_set(key, value)
        self.run(:cache, :set, key, value)
      end

      def self.cache_get(key)
        self.run(:cache, :get, key)
      end
      
      def self.search_cache_set(key, value)
        self.run(:search_cache, :set, key, value)
      end

      def self.search_cache_get(key)
        self.run(:search_cache, :get, key)
      end

      def self.document_set(hash, document)
        self.run(:document, :set, hash, document)
      end

      def self.document_get(hash)
        self.run(:document, :get, hash)
      end

      def self.metadata_set(hash, metadata)
        self.run(:metadata, :set, hash, metadata)
      end

      def self.metadata_get(hash)
        self.run(:metadata, :get, hash)
      end
      
      def self.postings_block_get(id)
        self.run(:postings_block, :get, id)
      end
      
      def self.postings_block_set(id, data)
        self.run(:postings_block, :set, id, data)
      end
      
      def self.postings_block_batch_set(pairs)
        self.run(:postings_block, :batch_set, pairs)
      end
      
      def self.postings_block_delete(id)
        self.run(:postings_block, :delete, id)
      end
      
      def self.postings_metadata_get(word)
        self.run(:postings_metadata, :get, word)
      end
      
      def self.postings_metadata_set(word, data)
        self.run(:postings_metadata, :set, word, data)
      end
      
      def self.postings_metadata_batch_set(pairs)
        self.run(:postings_metadata, :batch_set, pairs)
      end
      
      def self.run(resource, action, *parameters)
        server = DRbObject.new(nil, Config.database_connection)
        server.execute(resource, action, parameters)
      end
    end
  end
end
