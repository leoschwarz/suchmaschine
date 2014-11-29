require 'drb/drb'
require 'drb/acl'
require 'digest/md5'

# URL: https://en.wikibooks.org/wiki/Ruby_Programming/Standard_Library/DRb

module Database
  class Server
    def initialize
      @logger = Common::Logger.new
      @logger.add_output($stdout, Common::Logger::INFO)
      @backend = Database::Backend.new
    end
    
    def start
      front_object = ServerFront.new(self)
      directive = (["deny", "all"] + Config.database.client_whitelist.map{|ip| ["allow", ip]}).flatten
      DRb.install_acl(ACL.new(directive))
      DRb.start_service(Config.database_connection, front_object)
      @logger.log_info "Datenbank Server gestartet."
      DRb.thread.join
    end
    
    def stop
      @logger.log_info "Datenbank wird heruntergefahren."
      @backend.save
      @logger.log_info "Daten erfolgreich gespeichert."
    end
    
    def has_metadata?(url)
      @backend.datastore_haskey?(Digest::MD5.hexdigest(url))
    end
    
    def handle_queue_insert(queue, items)
      if queue == :download
        items.each do |url|
          @backend.queue_insert(:download, url) unless has_metadata?(url)
        end
      elsif queue == :index
        items.each do |id|
          @backend.queue_insert(id)
        end
      end

      nil
    end
    
    def handle_queue_fetch(queue)
      if queue == :download
        while has_metadata? (url = @backend.queue_fetch(:download)); end
        url
      elsif queue == :index
        @backend.queue_fetch(:index)
      end
    end
    
    def handle_datastore_set(datastore, key, value)
      @backend.datastore_set(datastore, key, value)
      nil
    end
    
    def handle_datastore_batch_set(datastore, pairs)
      @backend.datastore_batchset(datastore, pairs)
      nil
    end
    
    def handle_datastore_get(datastore, key)
      @backend.datastore_get(datastore, key)
    end
    
    def handle_datastore_delete(datastore, key)
      @backend.datastore_delete(datastore, key)
      nil
    end
  end
end
