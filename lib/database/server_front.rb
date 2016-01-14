# Copyright (c) 2014-2016 Leonardo Schwarz <mail@leoschwarz.com>
#
# This file is part of BreakSearch.
#
# BreakSearch is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License version 3
# as published by the Free Software Foundation.
#
# BreakSearch is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with BreakSearch. If not, see <http://www.gnu.org/licenses/>.

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

  # The ServerFront is the object that will be shared over DCell and manages client access.
  class ServerFront < BlankObject
    include Celluloid

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
