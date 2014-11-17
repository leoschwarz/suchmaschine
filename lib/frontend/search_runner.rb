module Frontend
  class SearchRunner
    attr_accessor :results, :results_count
    
    def initialize(query)
      @query = query
      
      # Alle Sonderzeichen entfernen
      @query.gsub!(/[^a-zA-ZäöüÄÖÜ]+/, " ")
      
      # Kleinschreiben
      @query.downcase!
    end
    
    def run
      # Überprüfen ob es bereits einen Cache-Eintrag gibt.
      if (cache_item = SearchCacheItem.load(@query)) && cache_item.valid?
        @cache_item = cache_item
        return
      end
      
      # Der Hash results beinhaltet den jeweiligen Score für jedes Dokument (ID => Score)
      results = Hash.new(0)
      @query.split(" ").uniq.each do |word|
        postings = Frontend::Postings.new(word, temporary: false, load: true)
        
        blocks = postings.sorted_blocks
        
        if blocks.size > 0
          # TODO: Falls im ersten Block nicht alle relevanten Ergebnisse sind, weitere Blöcke laden...
          block = blocks[0]
          block.fetch
          block.entries.each do |frequency, occurences, id|
            corpus_count = postings.rows_count
            results[id] += Math.log( frequency / corpus_count)
          end
        end
      end
      
      # Cache schreiben
      @cache_item = SearchCacheItem.create(@query, results.sort_by{|_, score| score}.reverse)
    end
    
    def results_count
      run if @cache_item.nil?
      @cache_item.documents.size.to_i
    end
    
    def pages_count
      run if @cache_item.nil?
      (results_count.to_f / 10).ceil
    end
    
    def page(page_number=1)
      run if @cache_item.nil?
      
      i = page_number-1
      @cache_item.documents[10*i...10*(i+1)].map{|id, score| [Frontend::Metadata.fetch(id), score]}
    end
  end
end
