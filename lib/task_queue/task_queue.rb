# Max-Binary-Heap
#
# Literatur:
# http://www.cse.hut.fi/en/research/SVG/TRAKLA2/tutorials/heap_tutorial/index.html
# http://cs.lmu.edu/~ray/notes/pqueues/

module TaskQueue
  class TaskQueueItem
    attr_accessor :value, :priority
    def initialize(value, priority)
      @value = value
      @priority = priority
    end
  end

  class TaskQueue
    def initialize(save = false, save_location = "/dev/null")
      @heap = []
      @hash = {}
      @save = File.open(save_location, "a") if save
    end
    
    def insert(url, priority=0)
      if @hash.has_key? url
        increase_priority(url)
      else
        # Nur wenn die Limite noch nicht erreicht wurde, wird die URL hinzugefügt.
        # Andererseits wird einfach geloggt und die URL erst später richtig abgearbeitet.
        if TaskQueue.config.max_size > size
          index = heap_insert(TaskQueueItem.new(url, priority))
          @hash[url] = index
        end
        
        unless @save.nil?
          @save.write("INSERT\t#{url}\t#{priority}\n")
        end
      end
    end
  
    def increase_priority(url, factor=1)
      index = @hash[url]
      heap_increase(index, factor)
      
      unless @save.nil?
        @save.write("INCREASE\t#{url}\t#{factor}\n")
      end
    end
  
    def fetch
      url = heap_delete_max
      
      unless @save.nil?
        @save.write("DELETE\t#{url}\n")
      end
      
      url
    end
  
    def size
      @heap.size
    end
    
    # Dies lädt nicht nur die Daten, sondern reinigt die Datei auch.
    def load_from_disk
      # Daten laden
      @save.close
      data = {}
      file = File.open(@save.path, "r")
      file.each_line do |line|
        fields = line.strip.split("\t")
        
        if fields[0] == "INSERT"
          url = fields[1]
          priority = fields[2]
          
          # Wenn die maximale Grösse erreicht wurde, kann es dazu kommen, dass ein INSERT mehrfach nacheinander im Log vorkommt.
          # Dies entspräche dann einer Erhöhung der Priorität.
          if data.has_key? url
            data[url] += priority.to_i
          else
            data[url] = priority.to_i
          end
        elsif fields[0] == "INCREASE"
          url = fields[1]
          factor = fields[2]
          data[url] += factor.to_i
        elsif fields[0] == "DELETE"
          url = fields[1]
          data.delete url
        end
      end
      file.close
      
      # Die Daten laden (dies schreibt auch automatisch das neue Logfile)
      @save = File.new(@save.path, "w")
      data.each_pair do |url, priority|
        insert(url, priority)
      end
    end
  
    ##################################################
    # Methoden für @heap
    ##################################################
    private
    def heap_insert(item)
      @heap << item
      current_index = size - 1
      parent_index  = _heap_parent_of(current_index)
    
      while not parent_index.nil? and item.priority > @heap[parent_index].priority
        _swap(current_index, parent_index)
      
        current_index = parent_index
        parent_index = _heap_parent_of(parent_index)
      end
    
      current_index
    end
  
    def heap_increase(current_index, factor)
      @heap[current_index].priority += factor
    
      parent_index = _heap_parent_of(current_index) 
      while not parent_index.nil? and @heap[current_index].priority > @heap[parent_index].priority
        _swap(current_index, parent_index)
        current_index = parent_index
        parent_index  = _heap_parent_of(current_index)
      end
    
      @heap[current_index].priority
    end
  
    def heap_get_max
      return @heap[0]
    end
  
    def heap_delete_max()
      deleted_item = @heap[0]
      @heap[0] = @heap[size - 1]
      @heap.delete_at(@heap.size - 1)
      @hash.delete deleted_item.value
    
      current_index = 0
      while not current_index.nil?
        left_child  = _heap_left_child_of(current_index)
        right_child = _heap_right_child_of(current_index)
      
        if left_child.nil?
          # Wir sind bereits ganz unten
          current_index = nil
        elsif right_child.nil?
          # Es gibt nur einen linken Kindknoten, dh. nur etwas mit dem verglichen werden muss
          if @heap[left_child].priority > @heap[current_index].priority
            _swap(left_child, current_index)
            current_index = left_child
          else
            current_index = nil
          end
        else
          # Es gibt einen rechten und einen linken Kindknoten, wir ersetzen aber nur mit dem grösseren
          # Falls aber beide Kindknoten kleiner sind, sind wir natürlich auch fertig.
          if @heap[left_child].priority >= @heap[right_child].priority
            if @heap[left_child].priority > @heap[current_index].priority
              _swap(left_child, current_index)
              current_index = left_child
            else
              current_index = nil
            end
          else
            if @heap[right_child].priority > @heap[current_index].priority
              _swap(right_child, current_index)
              current_index = right_child
            else
              current_index = nil
            end
          end
        end
      end
      deleted_item.value
    end
  
    ##################################################
    # Hilfs Methoden
    ##################################################
    private
    def _swap(index_1, index_2)
      @hash[@heap[index_1].value], @hash[@heap[index_2].value] = index_2, index_1
      @heap[index_1], @heap[index_2] = @heap[index_2], @heap[index_1]
    end
  
    def _heap_parent_of(index)
      if index == 0
        nil
      else
        (index-1)/2
      end
    end
  
    def _heap_left_child_of(index)
      left = 2*index + 1
      if left >= size
        nil
      else
        left
      end
    end
  
    def _heap_right_child_of(index)
      right = 2*index + 2
      if right >= size
        nil
      else
        right
      end
    end
  end
end
