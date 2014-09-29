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
# DOCUMENT_SET\tURL1\tDOCUMENT1[...]
# DOCUMENT_GET\tURL1[...]
# 
#
# ALTE API ::
# TASK_INSERT\tURL1[\tURL2\t...]\n
# TASK_FETCH\tN\n
# STATE_GET\tURL1[\tURL2\t...]\n
# STATE_SET\tURL1\tSTATE1[\t...]\n
# DOCDATA_GET\tURL1[\tURL2\t...]\n
# DOCDATA_SET\tURL1\tDATA1[\t...]\n

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
    
    def handle_document_set(paired_data)
      paired_data.each_slice(2) do |url, document|
        DocumentStorage.set(url, document)
      end
      nil
    end
    
    def handle_document_get(urls)
      urls.map{ |url| DocumentStorage.get(url) }.join("\t")
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
          
          
          # BEGINN ALTER CODE
          when request[0] == "TASK_INSERT"
            request[1..-1].each{|url| queue.insert(url) }
            String.new
          when request[0] == "TASK_FETCH"
            num = request[1].to_i
            urls = []
            num.times{ urls << queue.fetch }
            urls.join("\t")
          when request[0] == "STATE_GET"
            urls = request[1..-1]
            urls.map{|url| db.get("url.state.#{url}")}.join("\t")
          when request[0] == "STATE_SET"
            pairs = (request.size-1) / 2
            (0...pairs).each do |i|
              db.put("url.state.#{request[2*i+1]}", request[2*i+2])
            end
            String.new
          when request[0] == "DOCDATA_GET"
            urls = request[1..-1]
            urls.map{|url| db.get("doc.data.#{url}")}.join("\t")
          when request[0] == "DOCDATA_SET"
            pairs = (request.size-1) / 2
            (0...pairs).each do |i|
              db.put("doc.data.#{request[2*i+1]}", request[2*i+2])
            end
            String.new
          # ENDE ALTER CODE
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
