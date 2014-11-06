require 'leveldb'
require 'lz4-ruby'
require 'digest/md5'

module Database
  class Server
    def initialize
      @logger = Common::Logger.new
      @logger.add_output($stdout, Common::Logger::INFO)
      
      @server = Common::FastServer.new(Config.database_connection.host, Config.database_connection.port, @logger)
      @server.on_start do
        @queues = {
          :download => BetterQueue.new(Config.paths.download_queue),
          :index    => BetterQueue.new(Config.paths.index_queue)
        }
      end

      @server.on_error do |error|
        @logger.log_exception(error)
      end

      @server.on_stop do
        @queues[:download].save
        @queues[:index].save
        @logger.log_info "Daten erfolgreich gespeichert."
      end

      @server.on_request do |request|
        action, parameters = request.split("\t", 2)
        handle_action(action, parameters)
      end
      
      @leveldb = LevelDB::DB.new(Config.paths.leveldb)
    end

    def start
      @server.start
    end

    # Verschiedene Handler für verschiedene Aktionen
    def handle_action(action, parameters)
      case action
        when "DOWNLOAD_QUEUE_INSERT" # URL1\tURL2...
          handle_queue_insert(:download, parameters.split("\t"))
        when "DOWNLOAD_QUEUE_FETCH" # 
          handle_queue_fetch(:download)
        when "INDEX_QUEUE_INSERT" # DOC_HASH1\tDOC_HASH2...
          handle_queue_insert(:index, parameters.split("\t"))
        when "INDEX_QUEUE_FETCH" #
          handle_queue_fetch(:index)
        when "INDEX_GET" # WORD
          index_file = Common::IndexFile.new(Config.paths.index+"word:#{parameters}")
          if File.exist? index_file.path
            index_file.read_entries.join("\t")
          else
            nil
          end
        when "CACHE_SET" # KEY VALUE
          key, value = parameters.split("\t", 2)
          @leveldb.put("cache:#{key}", value)
        when "CACHE_GET" # KEY
          key = parameters
          @leveldb.get(key)
        when "DOCUMENT_SET" # ID VALUE
          id, value = parameters.split("\t", 2)
          @leveldb.put("doc:#{id}", value)
        when "DOCUMENT_GET" # ID
          id = parameters
          @leveldb.get("doc:#{id}")
        when "METADATA_SET" # ID DATA
          id, data = parameters.split("\t", 2)
          handle_queue_insert(:index, [id])
          @leveldb.put("meta:#{id}", data)
        when "METADATA_GET" # ID
          id = parameters
          @leveldb.get("meta:#{id}")
        else
          @logger.log_error "Unbekanter Datenbank Befehl #{action} mit Parameter: #{parameters}"
      end
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

    def has_metadata?(url)
      File.exist?(Config.paths.metadata + Digest::MD5.hexdigest(url))
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
