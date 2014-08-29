# Max-Binary-Heap
#
# Literatur:
# http://www.cse.hut.fi/en/research/SVG/TRAKLA2/tutorials/heap_tutorial/index.html
# http://cs.lmu.edu/~ray/notes/pqueues/


class TaskQueueItem
  attr_accessor :value, :priority
  def initialize(value, priority)
    @value = value
    @priority = priority
  end
end

class TaskQueue
  def initialize
    @_heap = []
    @_hash = {}
  end
  
  def insert(url, priority=0)
    if @_hash.has_key? url
      increase_priority(url)
    else
      index = heap_insert(TaskQueueItem.new(url, priority))
      @_hash[url] = index
    end
  end
  
  def increase_priority(url, factor=1)
    index = @_hash[url]
    heap_increase(index, factor)
  end
  
  def fetch
    heap_delete_max
  end
  
  def size
    @_heap.size
  end
  
  ##################################################
  # Methoden für @_heap
  ##################################################
  private
  def heap_insert(item)
    @_heap << item
    current_index = size - 1
    parent_index  = _heap_parent_of(current_index)
    
    while not parent_index.nil? and item.priority > @_heap[parent_index].priority
      _swap(current_index, parent_index)
      
      current_index = parent_index
      parent_index = _heap_parent_of(parent_index)
    end
    
    current_index
  end
  
  def heap_increase(current_index, factor)
    @_heap[current_index].priority += factor
    
    parent_index = _heap_parent_of(current_index) 
    while not parent_index.nil? and @_heap[current_index].priority > @_heap[parent_index].priority
      _swap(current_index, parent_index)
      current_index = parent_index
      parent_index  = _heap_parent_of(current_index)
    end
    
    @_heap[current_index].priority
  end
  
  def heap_get_max
    return @_heap[0]
  end
  
  def heap_delete_max()
    deleted_item = @_heap[0]
    @_heap[0] = @_heap[size - 1]
    @_heap.delete_at(@_heap.size - 1)
    @_hash.delete deleted_item.value
    
    current_index = 0
    while not current_index.nil?
      left_child  = _heap_left_child_of(current_index)
      right_child = _heap_right_child_of(current_index)
      
      if left_child.nil?
        # Wir sind bereits ganz unten
        current_index = nil
      elsif right_child.nil?
        # Es gibt nur einen linken Kindknoten, dh. nur etwas mit dem verglichen werden muss
        if @_heap[left_child].priority > @_heap[current_index].priority
          _swap(left_child, current_index)
          current_index = left_child
        else
          current_index = nil
        end
      else
        # Es gibt einen rechten und einen linken Kindknoten, wir ersetzen aber nur mit dem grösseren
        # Falls aber beide Kindknoten kleiner sind, sind wir natürlich auch fertig.
        if @_heap[left_child].priority >= @_heap[right_child].priority
          if @_heap[left_child].priority > @_heap[current_index].priority
            _swap(left_child, current_index)
            current_index = left_child
          else
            current_index = nil
          end
        else
          if @_heap[right_child].priority > @_heap[current_index].priority
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
    @_hash[@_heap[index_1].value], @_hash[@_heap[index_2].value] = index_2, index_1
    @_heap[index_1], @_heap[index_2] = @_heap[index_2], @_heap[index_1]
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
