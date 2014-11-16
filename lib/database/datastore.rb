require 'leveldb-native'

module Database
  class Datastore
    # TODO: In Konfiguration auslagern...
    BLOCKSIZES = {document: 256, 
     metadata: 8,
        cache: 8,
     postings_block: 256,
     postings_metadata: 8}
    
    def initialize(name)
      options = {}
      options[:create_if_missing] = true
      options[:compression]       = LevelDBNative::CompressionType::SnappyCompression
      options[:block_size]        = BLOCKSIZES[name] * 1024
      options[:write_buffer_size] = 16 * 1024*1024
      
      @db = LevelDBNative::DB.new(Config.paths[name], options)
    end
    
    def put(key, value)
      
    end
    
    def get(key)
      
    end
    
    def delete(key)
      
    end
  end
end
