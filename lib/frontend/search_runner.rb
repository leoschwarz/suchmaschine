############################################################################################
# Der SearchRunner führt die eigentliche Suchanfrage aus. Dazu wird die Suchanfrage in     #
# einzelne Stichworte zerlegt. Danach werden Index-Einträge geladen und die relevantesten  #
# Dokumente bestimmt und später vom Webserver angezeigt.                                   #
############################################################################################
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
      if (cache_item = SearchCacheItem.load(@db, @query)) && cache_item.valid?
        @cache_item = cache_item
        return
      end

      # Der Hash results beinhaltet den jeweiligen Score für jedes Dokument (ID => Score)
      results = Hash.new(0)
      @query.split(" ").uniq.each do |word|
        _, count, position = @index.metadata.find(word)

        if count != nil && position != nil
          @index.row_reader.read(position, count) do |tf, doc|
            idf = Math.log( @index.metadata.documents_count.to_f / count )
            score = tf * idf
            results[doc] += score
          end
        end
      end

      # Cache schreiben
      @cache_item = SearchCacheItem.create(@db, @query, results.sort_by{|_,score| score}.reverse)
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
      return [] if page_number < 1 || page_number > pages_count

      i = page_number-1
      documents = @cache_item.documents[10*i...10*(i+1)]
      documents.map do |id, score|
        raw = @db.datastore_get(:metadata, id)
        metadata = Common::Database::Metadata.deserialize(raw)
        metadata.url = Common::URL.stored(metadata.url)
        [metadata, score]
      end
    end
  end
end
