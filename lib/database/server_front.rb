module Database
  # TODO: Methoden wie instance_eval von dieser Klasse entfernen, da diese eine grosse Sicherheitslücke darstellen!,
  #       bzw. den Zugriff auf den Server nur von bestimmten IPs erlauben...
  class ServerFront
    def initialize(server)
      @server = server
      
      # Mutex für die einzelnen Ressourcen der Datenbank erzeugen.
      # Zugriffe zu verschiedenen Ressourcen können so zur selben Zeit erfolgen.
      @mutex = {}
      [:download_queue, :index_queue, :cache, :document, :metadata, :postings_block, :postings_metadata].each{|i| @mutex[i] = Mutex.new}
    end
    
    def execute(resource, action, parameters)
      @mutex[resource].synchronize do
        case resource
        when :download_queue
          handle_queue(:download, action, parameters)
        when :index_queue
          handle_queue(:index, action, parameters)
        when :cache
          handle_datastore(:cache, action, parameters)
        when :document
          handle_datastore(:document, action, parameters)  
        when :metadata
          handle_datastore(:metadata, action, parameters)
        when :postings_block
          handle_datastore(:postings_block, action, parameters)
        when :postings_metadata
          handle_datastore(:postings_metadata, action, parameters)
        end
      end
    end
    
    private
    def handle_queue(queue_name, action, parameters)
      if action == :insert
        @server.handle_queue_insert(queue_name, parameters.flatten)
      elsif action == :fetch
        @server.handle_queue_fetch(queue_name)
      else
        raise "Unbekannte Aktion: '#{action}'"
      end
    end
    
    def handle_datastore(datastore_name, action, parameters)
      if action == :set
        @server.handle_datastore_set(datastore_name, parameters[0], parameters[1])
      elsif action == :get
        @server.handle_datastore_get(datastore_name, parameters[0])
      elsif action == :delete
        @server.handle_datastore_delete(datastore_name, parameters[0])
      else
        raise "Unbekannte Aktion: '#{action}'"
      end
    end
  end
end
