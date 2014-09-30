#!/usr/bin/env ruby

require 'bundler/setup'
require 'socket'
require_relative '../lib/database/database'
require_relative '../config/config.rb'

load_configuration(Database, "database.yml")

# API Dokumentation :: 
# 
# [...] = Weitere Tab-getrennte Werte(paare)
#
# QUEUE_INSERT\tURL1[...]
# QUEUE_FETCH
# DOCUMENT_SET\tURL\tDOCUMENT
# DOCUMENT_GET\tURL
# DOCUMENT_INFO_SET\tURL\tDOCUMENT_INFO
# DOCUMENT_INFO_GET\tURL


module Database
  class Server
    def initialize
      puts "Die Warteschlange wird geladen und optimiert..."
      @queue = TaskQueue.new(Database.config.task_queue.storage_path)
      @queue.load_from_disk
      puts "Es wurden #{@queue.size} Einträge geladen."
    end
    
    def handle_queue_insert(urls)
      urls.each do |url|
        @queue.insert(url)
      end
      nil
    end
    
    def handle_queue_fetch
      url = @queue.fetch
      while Storage.include? url
        url = @queue.fetch
      end
      url
    end
    
    def handle_document_set(url, document)
      StorageHDD.instance.set("doc:"+url, document)
      nil
    end
    
    def handle_document_get(url)
      StorageHDD.instance.get("doc:"+url)
    end
    
    def handle_document_info_set(url, docinfo)
      StorageSSD.instance.set("docinfo:"+url, docinfo)
      nil
    end
    
    def handle_document_info_get(url)
      StorageSSD.instance.get("docinfo:"+url)
    end
    
    def run
      socket = TCPServer.new 2051
      puts "Der Server läuft nun auf Port 2051."
    
      loop do
        client = socket.accept
      
        buffer = client.recv(10_000_000)
        request = buffer.split("\t")
            
        response = case
          when request[0] == "QUEUE_INSERT"
            handle_queue_insert(request[1..-1])
          when request[0] == "QUEUE_FETCH"
            handle_queue_fetch
          when request[0] == "DOCUMENT_SET"
            handle_document_set(request[1], request[2])
          when request[0] == "DOCUMENT_GET"
            handle_document_get(request[1])
          when request[0] == "DOCUMENT_INFO_SET"
            handle_document_info_set(request[1], request[2])
          when request[0] == "DOCUMENT_INFO_GET"
            handle_document_info_get(request[1])
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
