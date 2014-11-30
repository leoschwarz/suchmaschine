module Frontend
  class SearchRunner
    attr_accessor :results, :results_count
    
    def initialize(index, db, query)
      @index = index
      @db    = db
      @query = query
      
      # Eingabe bereinigen
      @query.gsub!(/[^a-zA-ZäöüÄÖÜ]+/, " ")
      @query.downcase!
    end
    
    def run
      # Überprüfen ob es bereits einen Cache-Eintrag gibt.
      #if (cache_item = SearchCacheItem.load(@query)) && cache_item.valid?
      #  @cache_item = cache_item
      #  return
      #end
      
      # Der Hash results beinhaltet den jeweiligen Score für jedes Dokument (ID => Score)
      results = Hash.new(0)
      @query.split(" ").uniq.each do |word|
        count, position = @index.metadata[word]
        
        if count != nil && position != nil
          @index.row_reader.read(position, count) do |tf, doc|
            idf = 1 # <- TODO!!
            score = tf * idf
            results[doc] += score
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
      @cache_item.documents[10*i...10*(i+1)].map do |id, score|
        raw = @db.datastore_get(:metadata, id)
        metadata = Common::Database::Metadata.deserialize(raw)
        metadata.url = Common::URL.stored(metadata.url)
        [metadata, score]
      end
    end
  end
end
