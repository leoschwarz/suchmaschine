require 'drb/drb'
require 'leveldb-native'
require 'lz4-ruby'
require 'digest/md5'

# URL: https://en.wikibooks.org/wiki/Ruby_Programming/Standard_Library/DRb

module Database
  # TODO: Methoden wie instance_eval von dieser Klasse entfernen, da diese eine grosse Sicherheitslücke darstellen!,
  #       bzw. den Zugriff auf den Server nur von bestimmten IPs erlauben...
  # TODO: Mutex per Resource (also einen für DownloadQueue, einen für IndexQueue, etc...)
  class ServerFront
    def initialize(server)
      @server = server
      @run_mutex = Mutex.new
    end
    
    def execute(command, *args)
      # Mit dem Mutex wird verhindert, dass zwei Threads zur selben Zeit auf der Datenbank
      # arbeiten. Jede Anfrage führt die Methode ServerFront.execute nämlich in einem eigenen Thread aus.
      @run_mutex.synchronize do
        return @server.execute(command, args)
      end
    end
  end
  
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
      {document: 256, metadata: 8, cache: 8, postings: 256, postings_metadata: 8}.each_pair do |name, kb|
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
    
    def execute(action, parameters)
      parameters = parameters[0]
      case action
      when :download_queue_insert # URL1\tURL2...
        handle_queue_insert(:download, parameters.flatten)
      when :download_queue_fetch # 
        handle_queue_fetch(:download)
      when :index_queue_insert # DOC_HASH1\tDOC_HASH2...
        handle_queue_insert(:index, parameters.flatten)
      when :index_queue_fetch #
        handle_queue_fetch(:index)
      when :index_get # WORD
        # TODO
        index_file = Common::IndexFile.new(Config.paths.index+"word:#{parameters}")
        if File.exist? index_file.path
          index_file.read_entries.join("\t")
        else
          nil
        end
      when :cache_set # KEY VALUE
        key, value = parameters[0], parameters[1]
        @data_stores[:cache].put(key, value)
        nil
      when :cache_get # KEY
        key = parameters[0]
        @data_stores[:cache].get(key)
      when :document_set # ID VALUE
        id, value = parameters[0], parameters[1]
        @data_stores[:document].put(id, value)
        nil
      when :document_get # ID
        id = parameters[0]
        @data_stores[:document].get(id)
      when :metadata_set # ID DATA
        id, data = parameters[0], parameters[1]
        handle_queue_insert(:index, [id])
        @data_stores[:metadata].put(id, data)
        nil
      when :metadata_get # ID
        id = parameters[0]
        @data_stores[:metadata].get(id)
      when :postings_set # word, block, data
        id, data = parameters
        @data_stores[:postings].put(id, data)
        nil
      when :postings_get # word, block
        id = parameters[0]
        @data_stores[:postings].get(id)
      when :postings_metadata_set # word, data
        word, data = parameters
        @data_stores[:postings_metadata].put(word, data)
        nil
      when :postings_metadata_get # word
        word = parameters[0]
        @data_stores[:postings_metadata].get(word)
      else
        @logger.log_error "Unbekanter Datenbank Befehl #{action} mit Parameter: #{parameters}"
      end
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
        items.each do |docinfo_key|
          @queues[:index].insert(docinfo_key)
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
  end
end
