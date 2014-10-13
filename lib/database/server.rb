require 'lz4-ruby'
require 'digest/md5'

module Database
  class Server
    def initialize
      @server = Common::FastServer.new(Config.database_connection.host, Config.database_connection.port)
      @server.on_start do
        @queues = {
          :download => BigQueue.new(Config.paths.download_queue),
          :index    => BigQueue.new(Config.paths.index_queue)
        }
      end

      @logger = Common::Logger.new
      @logger.add_output($stdout, Common::Logger::INFO)

      @server.on_error do |error|
        @logger.log_exception(error)
      end

      @server.on_stop do
        @queues[:download].save_everything
        @queues[:index].save_everything
        puts "Daten erfolgreich gespeichert."
      end

      @server.on_request do |request|
        action, parameters = request.split("\t", 2)
        handle_action(action, parameters)
      end
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
        when "CACHE_SET" # KEY VALUE
          key, value = parameters.split("\t", 2)
          write_file(Config.paths.cache+key, value)
        when "CACHE_GET" # KEY
          read_file(Config.paths.cache + parameters)
        when "DOCUMENT_SET" # ID VALUE
          id, value = parameters.split("\t", 2)
          write_file(Config.paths.document + id, value)
        when "DOCUMENT_GET" # ID
          read_file(Config.paths.document + parameters)
        when "METADATA_SET" # ID DATA
          id, data = parameters.split("\t", 2)
          handle_queue_insert(:index, [id])
          write_file(Config.paths.metadata+id, data)
        when "METADATA_GET" # ID
          read_file(Config.paths.metadata + parameters)
      end
    end

    def handle_queue_insert(queue, items)
      if queue == :download
        items.each do |url|
          @queues[:download].insert(url) unless has_doc_info?(url)
        end
      elsif queue == :index
        items.each do |docinfo_key|
          @queues[:index].insert(docinfo_key)
        end
      end

      nil
    end

    def has_doc_info?(url)
      File.exist?(Config.paths.metadata + Digest::MD5.hexdigest(url))
    end

    def handle_queue_fetch(queue)
      if queue == :download
        url = @queues[:download].fetch
        while has_doc_info? url
          url = @queues[:download].fetch
        end
        return url
      elsif queue == :index
        return @queues[:index].fetch
      end
    end
    
    # Datei-Inhalt oder leerer String
    def read_file(path)
      if File.exist? path
        LZ4.uncompress File.read(path)
      else
        ""
      end
    end
    
    def write_file(path, data)
      File.open(path, "w") do |file|
        file.write(LZ4.compress data)
      end
      nil
    end
  end
end
