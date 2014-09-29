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
# LINK_DATA_ADD\tURL1\tMETADATA1[...]
# LINK_DATA_GET\tURL1[...]
# LINK_DATA_DELETE\tURL1[...]
# DOCUMENT_SET\tURL\tDOCUMENT
# DOCUMENT_GET\tURL

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
      @queue.fetch
    end
    
    def handle_link_data_add(paired_data)
      paired_data.each_slice(2) do |url, metadata|
        LinkData.add(url, metadata)
      end
      nil
    end
    
    def handle_link_data_get(urls)
      urls.map{ |url| LinkData.get(url) }.join("\t")
    end
    
    def handle_link_data_delete(urls)
      urls.each do |url|
        LinkData.delete(url)
      end
      nil
    end
    
    def handle_document_set(url, document)
      DocumentStorage.set(url, document)
      nil
    end
    
    def handle_document_get(url)
      DocumentStorage.get(url)
    end
    
    
    def run
      socket = TCPServer.new 2051
      puts "Der Server läuft nun auf Port 2051."
    
      loop do
        client = socket.accept
      
        buffer = client.recv(10_000_000)
        request = buffer[0...-1].split("\t")
            
        response = case
          when request[0] == "QUEUE_INSERT"
            handle_queue_insert(request[1..-1])
          when request[0] == "QUEUE_FETCH"
            handle_queue_fetch
          when request[0] == "LINK_DATA_ADD"
            handle_link_data_add(request[1..-1])
          when request[0] == "LINK_DATA_GET"
            handle_link_data_get(request[1..-1])
          when request[0] == "LINK_DATA_DELETE"
            handle_link_data_delete(request[1..-1])
          when request[0] == "DOCUMENT_SET"
            handle_document_set(request[1..-1])
          when request[0] == "DOCUMENT_GET"
            handle_document_get(request[1..-1])
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
