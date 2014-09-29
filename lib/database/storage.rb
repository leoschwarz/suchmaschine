require 'singleton'

module Database
  # Key-Value Speicher für Webdokumente.
  # Pflegt eine Speicherhierarchie bestehend aus: RAM, SSD und HDD
  # Dazu wird ein LRU-Cache Mechanismus verwendet: 
  # https://de.wikipedia.org/wiki/Least_recently_used
  class Storage
    # Schreibt den Eintrag ins RAM (das kann zu auslagerungen führen)
    def self.set(key, document)
      StorageRAM.instance.set(key, document)
    end
    
    # Findet das Dokument für die URL 'url'.
    # Falls nichts gefunden wurde wird nil zurückgegeben.
    def self.get(key)
      if (result = StorageRAM.instance.get(key)) != nil
        return result
      elsif (result = StorageSSD.instance.get(key)) != nil
        return result
      end
      nil
    end
    
    # Gibt an ob ein Eintrag enthalten ist.
    def self.include?(key)
      StorageRAM.instance.include?(key) || StorageSSD.instance.include?(key)
    end
    
    # Löscht das Dokument aus der gesamten Hierarchie
    def self.delete(key)
      StorageRAM.instance.delete(key)
      StorageSSD.instance.delete(key)
    end
  end
end