require 'drb/drb'
require 'leveldb-native'
require 'digest/md5'

# URL: https://en.wikibooks.org/wiki/Ruby_Programming/Standard_Library/DRb

module Database
  class Server
    def initialize
      @logger = Common::Logger.new
      @logger.add_output($stdout, Common::Logger::INFO)
    end
    
    def start
      @queues = {}
      @queues[:download] = BetterQueue.new(Config.paths.download_queue)
      @queues[:index]    = BetterQueue.new(Config.paths.index_queue)
      
      @data_stores = {}
      {document: 256, 
       metadata: 8,
          cache: 8,
       postings_block: 256,
       postings_metadata: 8}.each_pair do |name, kb|
        options = {}
        options[:create_if_missing] = true
        options[:compression]       = LevelDBNative::CompressionType::SnappyCompression
        options[:block_size]        = kb * 1024
        options[:write_buffer_size] = 16 * 1024*1024
        @data_stores[name] = LevelDBNative::DB.new(Config.paths[name], options)
      end
      
      front_object = ServerFront.new(self)
      DRb.start_service(Config.database_connection, front_object)
      @logger.log_info "Datenbank Server gestartet."
      DRb.thread.join
    end
    
    def stop
      @logger.log_info "Datenbank wird heruntergefahren."
      @queues[:download].save
      @queues[:index].save
      @logger.log_info "Daten erfolgreich gespeichert."
    end
    
    def has_metadata?(url)
      @data_stores[:metadata].exists?(Digest::MD5.hexdigest(url))
    end
    
    def handle_queue_insert(queue, items)
      if queue == :download
        items.each do |url|
          @queues[:download].insert(url) unless has_metadata?(url)
        end
      elsif queue == :index
        items.each do |id|
          @queues[:index].insert(id)
        end
      end

      nil
    end
    
    def handle_queue_fetch(queue)
      if queue == :download
        url = @queues[:download].fetch
        while has_metadata? url
          url = @queues[:download].fetch
        end
        return url
      elsif queue == :index
        return @queues[:index].fetch
      end
    end
    
    def handle_datastore_set(datastore, key, value)
      @data_stores[datastore].put(key, value)
      nil
    end
    
    def handle_datastore_batch_set(datastore, pairs)
      @data_stores[datastore].batch do |batch|
        pairs.each do |key, value|
          batch.put(key, value)
        end
      end
      nil
    end
    
    def handle_datastore_get(datastore, key)
      @data_stores[datastore].get(key)
    end
    
    def handle_datastore_delete(datastore, key)
      @data_stores[datastore].delete(key)
    end
  end
end
