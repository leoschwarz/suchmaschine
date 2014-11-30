require 'leveldb-native'

module Database
  class Backend
    def initialize
      @queues = {}
      @queues[:download] = Database::BetterQueue.new(Config.paths.download_queue)
      @queues[:index]    = Database::BetterQueue.new(Config.paths.index_queue)
      
      @datastores = {}
      names = [:document, :metadata, :cache, :search_cache]
      names.each do |name|
        kb = Config.database.block_size[name]
        options = {}
        options[:create_if_missing] = true
        options[:compression]       = LevelDBNative::CompressionType::SnappyCompression
        options[:block_size]        = kb * 1024
        options[:write_buffer_size] = 16 * 1024*1024
        @datastores[name] = LevelDBNative::DB.new(Config.paths[name], options)
      end
    end
    
    def save
      @queues.each_pair do |name, queue|
        queue.save
      end
    end
    
    def datastore_set(datastore, key, value)
      @datastores[datastore].put(key, value)
    end
    
    def datastore_batchset(datastore, pairs)
      @datastores[datastore].batch do |batch|
        pairs.each do |key, value|
          batch.put(key, value)
        end
      end
    end
    
    def datastore_get(datastore, key)
      @datastores[datastore].get(key)
    end
    
    def datastore_delete(datastore, key)
      @datastores[datastore].delete(key)
    end
    
    def datastore_haskey?(datastore, key)
      @datastores[datastore].exists?(key)
    end
    
    def datastore_keys(datastore)
      @datastores[datastore].keys
    end
    
    def queue_fetch(queue)
      @queues[queue].fetch
    end
    
    def queue_insert(queue, row)
      @queues[queue].insert(row)
    end
  end
end
