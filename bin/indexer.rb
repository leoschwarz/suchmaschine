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
        if Dir.exist?(Config.paths.index_tmp)
          @logger.log_warning "Bitte das temporäre Index-Verzeichniss löschen."
          @logger.log_warning "Dieses befindet sich bei: #{Config.paths.index_tmp}"
        else
          Dir.mkdir(Config.paths.index_tmp)
        end

        # Einzelne Index-Dateien für alle Dokumente in der Indexierwarteschlange erstellen.
        cache = Indexer::IndexingCache.new(Config.paths.index_tmp)
        queue_mutex = Mutex.new

        Common::WorkerThreads.run(Config.indexer.threads, blocking:true) do
          while (key = queue_mutex.synchronize{ db.queue_fetch(:index) })
            Task.new(cache, key).run
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

        @logger.log_info "Zusammenführung abgeschlossen, Metaindex Generierung gestarted."
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
