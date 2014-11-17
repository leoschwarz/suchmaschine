module Frontend
  class WebPaginationEntry
    def initialize(page_number, query, current)
      @page_number = page_number
      @query       = query
      @current     = current
    end
    
    def current?
      @current
    end
    
    def url
      # TODO: Das hier ist noch nicht ganz korrekt... 
      "search?query=#{@query}&page=#{@page_number}"
    end
    
    def number
      @page_number
    end
  end
  
  # TODO: Zur Zeit ist das Ergebnis auf den letzten Seiten von langen Listen noch nicht optimal...
  #       BSP: 18 19 [20]           (wo ist der Rest?)
  
  class WebPagination
    MIN_BACK    = 3 # mindestens 3 Seiten zurück anzeigen... also bsp: 2 3 4 [5] 6 7 8 9 ...
    MAX_ENTRIES = 10
    
    def initialize(total_pages, current_page, query)
      @total_pages  = total_pages
      @current_page = current_page
      @query        = query
    end
    
    def entries
      start_at = @current_page - MIN_BACK
      start_at = 1 if start_at < 1
      
      stop_at = start_at + MAX_ENTRIES - 1
      stop_at = @total_pages if stop_at > @total_pages
      
      (start_at..stop_at).each.map{|index| WebPaginationEntry.new(index, @query, index == @current_page)}
    end
  end
end
