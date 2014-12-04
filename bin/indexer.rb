#!/usr/bin/env ruby
############################################################################################
# Diese Datei startet, falls sie direkt ausgeführt wird, den Indexierer.                   #
# Ansonsten werden lediglich das Common- und das Indexer-Modul geladen, ohne dass weiter   #
# etwas geschieht.                                                                         #
############################################################################################
require_relative '../lib/common/common.rb'
require_relative '../lib/database/database.rb'
require_relative '../lib/indexer/indexer.rb'
require 'fileutils'

# TODO hier noch etwas aufräumen...

module Indexer
  class Main
    def initialize
      labels = {tasks: "Aufgaben", tasks_per_second: "Aufgaben/s"}
      @logger = Common::Logger.new({labels: labels})
      @logger.add_output($stdout, Common::Logger::INFO)
    end
    
    def run
      @logger.log_info "Indexierer wurde gestartet."
      
      begin
        db = Database::Backend.new
      rescue => e
        @logger.log_warning("Die Datenbank wird bereits von einem Prozess verwendet.")
        @logger.log_exception(e)
        Kernel.exit
      end
      
      begin
        # Temporäres Verzeichnis für den Index überprüfen...
        # TODO: Sobald alles ideal funktioniert, automatisch den Inhalt des Ordners löschen...
        if Dir.exist?(Config.paths.index_tmp)
          raise "Bitte das tmp/index-Verzeichniss entleeren."
        else
          Dir.mkdir(Config.paths.index_tmp)
        end
        
        # Einzelne Index-Dateien für alle Dokumente in der Indexierwarteschlange erstellen.
        cache = Indexer::IndexingCache.new(Config.paths.index_tmp)
        queue_mutex = Mutex.new
        
        Common::WorkerThreads.run(20, blocking:true) do
          loop do
            key = queue_mutex.synchronize{ db.queue_fetch(:index) }
            break if key.nil?
          
            if (raw = db.datastore_get(:metadata, key))
              metadata = Common::Database::Metadata.deserialize(raw)
              Task.new(cache, metadata).run unless metadata.nil?
            end
          end
        end
        
        cache.final_flush
      
        db.save
        db = nil
      
        # Nun müssen die einzelnen Zwischenergebnisse aus dem temporären Index-Verzeichnis
        # in den Zielindex zusammengeführt werden.
        @logger.log_info "Die Einträge werden nun zusammengeführt..."
        
        destination = Common::IndexFile.new(Config.paths.index)
        destination.delete
        
        sources = Dir["#{dir}/*"].map{|path| Common::IndexFile.new(path).pointer_reader}
        merger = Indexer::Merger.new(destination.writer, sources)
        merger.merge
      
        @logger.log_info "Zusammenführung abgeschlossen, nun wird ein Index der Abschnitte des Index erstellt..."
        destination.reload
        destination.metadata.generate
      
        @logger.log_info "Generierung des Indexes ist nun abgeschlossen."
      rescue Exception => e
        db.save unless db.nil?
        raise e
      end
    end
  end
end

if __FILE__ == $0
  Indexer::Main.new.run()
end
