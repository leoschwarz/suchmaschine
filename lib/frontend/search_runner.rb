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
        @results = cache_item.documents.first(10).map{|id, score| [Frontend::Metadata.fetch(id), score]}
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
      
      @results_count = results.size
      @results = results.sort_by{|doc, score| score}.reverse.first(10).map{|id, score| [Frontend::Metadata.fetch(id), score]}
      
      # Cache schreiben
      SearchCacheItem.create(@query, results.sort_by{|_, score| score}.reverse)
    end
  end
end
