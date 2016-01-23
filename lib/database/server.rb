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

require 'dcell'
require 'digest/md5'

module Database
  # The Server provides the ServerFront object over the DCell protocol and also acts as the interface
  # between ServerFront and Backend.
  class Server
    def initialize
      @logger = Common::Logger.new
      @logger.add_output($stdout, Common::Logger::INFO)
      @backend = Database::Backend.new
    end

    def start
      # Create new instance object to serve over the network.
      #front_object = ServerFront.new(self)

      # Setup DCell server.
      DCell.start(id: 'database_front', url: Config.database_connection)
      ServerFront.supervise_as(:database_front)
      #front_object.supervise_as(:database_front)
      sleep
    end

    def stop
      @logger.log_info "Datenbank wird heruntergefahren."
      @backend.save
      @logger.log_info "Daten erfolgreich gespeichert."
    end

    def has_metadata?(url)
      @backend.datastore_haskey?(:metadata, Digest::MD5.hexdigest(url))
    end

    def handle_queue_insert(queue, items)
      if queue == :download
        items.each do |url|
          @backend.queue_insert(:download, url) unless has_metadata?(url)
        end
      elsif queue == :index
        items.each do |id|
          @backend.queue_insert(:index, id)
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
