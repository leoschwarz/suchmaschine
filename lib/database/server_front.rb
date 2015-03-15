############################################################################################
# Die ServerFront stellt das Objekt dar, welches der Datenbankserver über das DRuby        #
# Protokoll teilt, und welches von einem Client als Zugangspunkt in die Datenbank dient.   #
############################################################################################
module Database
  # Sowohl Object, als auch BasicObject, werden mitsamt gefährlicher Methoden, wie
  # 'instance_eval' und 'class_eval' definiert. Deshalb werden von dieser Klasse alle
  # Methoden entfernt, die nicht unbedingt notwendig sind, um das ServerFront Objekt
  # sicher zu machen.
  class BlankObject
    safe_methods = [:__send__, :__id__, :object_id, :private_methods, :protected_methods]
    (instance_methods - safe_methods).each do |method|
      undef_method method
    end
  end

  class ServerFront < BlankObject
    def initialize(server)
      @server = server

      # Mutex für die einzelnen Ressourcen der Datenbank erzeugen.
      # Zugriffe zu verschiedenen Ressourcen können so zur selben Zeit erfolgen.
      @mutex = {}
      ressources = [:download_queue, :index_queue, :cache,
                    :search_cache, :document, :metadata]
      ressources.each{|i| @mutex[i] = Mutex.new}
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
        when :search_cache
          handle_datastore(:search_cache, action, parameters)
        when :document
          handle_datastore(:document, action, parameters)
        when :metadata
          handle_datastore(:metadata, action, parameters)
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
      elsif action == :batch_set
        @server.handle_datastore_batch_set(datastore_name, parameters[0])
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
