#!/usr/bin/env ruby

require 'bundler/setup'
require 'socket'
require 'lz4-ruby'
require 'digest/md5'
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
      puts "Die Warteschlange wird geladen und optimiert..."
      @queue = RandomQueue.new(Database.config.task_queue.storage_path)
      puts "Es wurden #{@queue.size} Einträge geladen."
    end
    
    def handle_queue_insert(urls)
      urls.each do |url|
        @queue.insert(url) unless has_doc_info?(url)
      end
      nil
    end
    
    def has_doc_info?(url)
      StorageSSD.instance.include?("docinfo:"+Digest::MD5.hexdigest(url))
    end
    
    def handle_queue_fetch
      url = @queue.fetch
      while has_doc_info? url
        url = @queue.fetch
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
    
    def run
      socket = TCPServer.new 2051
      puts "Der Server läuft nun auf Port 2051."
    
      loop do
        client = socket.accept
      
        buffer = client.recv(10_000_000)
        action, parameters = buffer.split("\t", 2)
            
        response = case action
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
        
        client.write response
        client.close
      end
    end
  end
end

if __FILE__ == $0
  Database::Server.new.run
end
