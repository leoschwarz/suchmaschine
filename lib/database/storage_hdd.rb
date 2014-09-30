require_relative './storage_disk.rb'

module Database
  class StorageHDD < StorageDisk
    def root_path
      Database.config.hdd.path
    end
    
    def max_size
      Database.config.hdd.max_size
    end
  end
end