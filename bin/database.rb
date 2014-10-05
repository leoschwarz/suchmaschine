#!/usr/bin/env ruby

require 'bundler/setup'
require 'lz4-ruby'
require 'digest/md5'
require_relative '../lib/common/common.rb'
require_relative '../lib/database/database'

Common::load_configuration(Database, "database.yml")

# API Dokumentation :: 
# 
# [...] = Weitere Tab-getrennte Werte(paare)
#
# DOWNLOAD_QUEUE_INSERT\tURL1[...]
# DOWNLOAD_QUEUE_FETCH
# INDEX_QUEUE_INSERT\tDOCINFO1[...]
# INDEX_QUEUE_FETCH
# CACHE_SET\tKEY\tVALUE
# CACHE_GET\tKEY
# DOCUMENT_SET\tURL\tDOCUMENT
# DOCUMENT_GET\tURL
# DOCUMENT_INFO_SET\tURL\tDOCUMENT_INFO -> Dies speichert die Dokumentinfo UND gibt dieses in die INDEX Warteschlange auf.
# DOCUMENT_INFO_GET\tURL


module Database
  class Server
    def initialize
      @server = Common::FastServer.new(Database.config.server.host, Database.config.server.port)
      @server.on_start do
        @queues = {
          :download => BigQueue.new(Database.config.download_queue.directory),
          :index    => BigQueue.new(Database.config.index_queue.directory)
        } 
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
        when "DOCUMENT_INFO_SET"
          key, value = parameters.split("\t", 2)
          doc_id = handle_document_info_set(key, value)
          handle_queue_insert(:index, doc_id)
        when "DOCUMENT_INFO_GET"
          handle_document_info_get(parameters)
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
      StorageSSD.instance.include?("docinfo:"+Digest::MD5.hexdigest(url))
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
    
    def handle_cache_set(key, value)
      StorageSSD.instance.set("cache:"+key, value)
      nil
    end
    
    def handle_cache_get(key)
      StorageSSD.instance.get("cache:"+key)
    end
    
    def handle_document_set(hash, document)
      StorageHDD.instance.set("doc:"+hash, document)
      nil
    end
    
    def handle_document_get(hash)
      StorageHDD.instance.get("doc:"+hash)
    end
    
    def handle_document_info_set(url, docinfo)
      doc_id = Digest::MD5.hexdigest(url)
      StorageSSD.instance.set("docinfo:"+doc_id, docinfo)
      doc_id
    end
    
    def handle_document_info_get(url)
      StorageSSD.instance.get("docinfo:"+Digest::MD5.hexdigest(url))
    end
  end
end

if __FILE__ == $0
  server = Database::Server.new
  server.start
end
