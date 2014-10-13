#!/usr/bin/env ruby

require 'bundler/setup'
require 'lz4-ruby'
require 'digest/md5'
require_relative '../lib/common/common.rb'
require_relative '../lib/database/database'


# API Dokumentation ::
#
# [...] = Weitere Tab-getrennte Werte(paare)
#
# DOWNLOAD_QUEUE_INSERT\tURL1[...]
# DOWNLOAD_QUEUE_FETCH
## INDEX_QUEUE_INSERT\tDOCINFO1[...]
## INDEX_QUEUE_FETCH
## INDEX_APPEND\tWORD1\tPOS1:DOC_HASH1[...] -> Fügt die jeweiligen DOC Einträge zu den Index Files hinzu.
## INDEX_GET\tWORD
# CACHE_SET\tKEY\tVALUE
# CACHE_GET\tKEY
# DOCUMENT_SET\tHASH\tDOCUMENT
# DOCUMENT_GET\tHASH
# METADATA_SET\tHASH\tDOCUMENT_INFO -> Dies speichert die Dokumentinfo UND gibt dieses in die INDEX Warteschlange auf.
# METADATA_GET\tHASH


module Database
  class Server
    def initialize
      # TODO
#      ["docinfo/", "index/", "cache/"].each do |subdirectory|
#        path = File.join(Database.config.ssd.path, subdirectory)
#        Dir.mkdir path unless Dir.exists? path
#      end

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
        when "DOWNLOAD_QUEUE_INSERT"
          handle_queue_insert(:download, parameters.split("\t"))
        when "DOWNLOAD_QUEUE_FETCH"
          handle_queue_fetch(:download)
        when "INDEX_QUEUE_INSERT"
          handle_queue_insert(:index, parameters.split("\t"))
        when "INDEX_QUEUE_FETCH"
          handle_queue_fetch(:index)
        when "INDEX_APPEND"
          pairs = parameters.split("\t").each_slice(2)
          handle_index_append(pairs)
        when "INDEX_GET"
          handle_index_get(parameters)
        when "CACHE_SET"
          key, value = parameters.split("\t", 2)
          handle_cache_set(key, value)
        when "CACHE_GET"
          handle_cache_get(parameters)
        when "DOCUMENT_SET"
          key, value = parameters.split("\t", 2)
          handle_document_set(key, value)
        when "DOCUMENT_GET"
          handle_document_get(parameters)
        when "METADATA_SET"
          hash, data = parameters.split("\t", 2)
          handle_metadata_set(hash, data)
          handle_queue_insert(:index, [hash])
        when "METADATA_GET"
          handle_metadata_get(parameters)
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

    def handle_index_append(pairs)
      pairs.each do |word, doc_id|
        Index.append(word, doc_id)
      end
    end

    def handle_index_get(word)
      Index.get(word).to_s.gsub(/\n/, "\t")
    end

    def handle_cache_set(key, value)
      write_file(Config.paths.cache+key, value)
      nil
    end

    def handle_cache_get(key)
      read_file(Config.paths.cache+key)
    end

    def handle_document_set(hash, document)
      write_file(Config.paths.document + hash, document)
      nil
    end

    def handle_document_get(hash)
      read_file(Config.paths.document + hash)
    end

    def handle_metadata_set(hash, metadata)
      write_file(Config.paths.metadata+hash, metadata)
      nil
    end

    def handle_metadata_get(hash)
      read_file(Config.paths.metadata+hash)
    end
    
    # Datei-Inhalt oder leerer String
    def read_file(path)
      if File.exist? path
        File.read(path)
      else
        ""
      end
    end
    
    def write_file(path, data)
      File.open(path, "w") do |file|
        file.write(data)
      end
    end
  end
end

if __FILE__ == $0
  server = Database::Server.new
  server.start
end
