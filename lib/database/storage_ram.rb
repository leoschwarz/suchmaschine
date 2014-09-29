module Database
  class StorageRAM
    include Singleton
  
    def initialize
      # Halter für die Daten
      @data  = Hash.new
      # Eine Warteschlange mit dem zunächst auszulagernden Element.
      # @queue[0] =Am kürzlichsten zugegriffen
      # @queue[-1]=Am längsten nicht zugegriffen
      @queue = Array.new
      # Summe der Bytegrössen der enthaltenen Einträge
      @size_current = 0
      # Maximalwert für @size_current sollte dieser Wert durch hinzufügen eines neuen Eintrages überschritten werden,
      # werden solange Daten ausgelagert bis genügend Platz vorhanden ist.
      # Hinweis: Es können keine Einträge hinzugefügt werden, deren Grösse grösser als dieser Wert ist.
      @size_limit = 100*1024*1024 # 100M , TODO: Diesen Wert in Konfigurationsdatei auslagern
    end
  
    def set(key, document)
      # Dokumentgrösse überprüfen
      document_size = document.bytesize
      if document_size >= @size_limit
        raise "Dokument zu gross!"
      end
    
      # Dokumente auslagern bis es genug Platz hat um das Element hinzuzufügen
      while document_size + @size_current > @size_limit
        swap_item
      end
    
      # Dokument setzen (und als neuesten Eintrag markieren)
      mark_newest_item(key, @data.has_key?(key))
      @data[key] = document
      @size_current += document_size
      nil
    end
  
    def get(key)
      if @data.has_key?(key)
        mark_newest_item(key, true)
        return @data[key]
      end
      nil
    end
    
    def delete(key)
      if @data.has_key?(key)
        @size_current -= @data[key].bytesize
        @data.delete(key)
        @queue.delete(key)
      end
      
      nil
    end
  
    private
    def mark_newest_item(key, delete_old)
      @queue.delete(key) if delete_old
      @queue.insert(0, key)
    end
  
    def swap_item
      # Das älteste Element abfragen
      key           = @queue[-1]
      document      = @data[key]
      document_size = document.bytesize
    
      # Das Element aus dem RAM löschen
      @data.delete(key)
      @queue.delete_at(-1)
    
      # Die grösse des RAM-Storage anpassen
      @size_current -= document_size
    
      # Das Element nun in die nächste Hierarchiestufe geben (SSD)
      StorageSSD.instance.set(key, document)
    end
  end
end