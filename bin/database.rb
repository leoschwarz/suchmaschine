#!/usr/bin/env ruby

require 'bundler/setup'
require 'socket'
require 'lz4-ruby'
require 'digest/md5'
require_relative '../lib/common/common.rb'
require_relative '../lib/database/database'
require_relative '../config/config.rb'

load_configuration(Database, "database.yml")

# API Dokumentation :: 
# 
# [...] = Weitere Tab-getrennte Werte(paare)
#
# QUEUE_INSERT\tURL1[...]
# QUEUE_FETCH
# CACHE_SET\tKEY\tVALUE
# CACHE_GET\tKEY
# DOCUMENT_SET\tURL\tDOCUMENT
# DOCUMENT_GET\tURL
# DOCUMENT_INFO_SET\tURL\tDOCUMENT_INFO
# DOCUMENT_INFO_GET\tURL


module Database
  class Server
    def initialize
      @server = Common::FastServer.new("0.0.0.0", 2051)
      @server.on_start do 
        @url_storage = URLStorage.new(Database.config.url_storage.directory)
      end
      
      @server.on_stop do
        @url_storage.save_everything
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
        when "QUEUE_INSERT"
          handle_queue_insert(parameters.split("\t"))
        when "QUEUE_FETCH"
          handle_queue_fetch
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
          handle_document_info_set(key, value)
        when "DOCUMENT_INFO_GET"
          handle_document_info_get(parameters)
      end
    end
    
    def handle_queue_insert(urls)
      urls.each do |url|
        @url_storage.insert(url) unless has_doc_info?(url)
      end
      nil
    end
    
    def has_doc_info?(url)
      StorageSSD.instance.include?("docinfo:"+Digest::MD5.hexdigest(url))
    end
    
    def handle_queue_fetch
      url = @url_storage.fetch
      while has_doc_info? url
        url = @url_storage.fetch
      end
      url
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
      StorageSSD.instance.set("docinfo:"+Digest::MD5.hexdigest(url), docinfo)
      nil
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
