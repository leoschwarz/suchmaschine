require_relative './storage_disk.rb'

module Database
  class StorageSSD < StorageDisk
    def root_path
      Database.config.ssd.path
    end

    def max_size
      Database.config.ssd.max_size
    end
  end
end
