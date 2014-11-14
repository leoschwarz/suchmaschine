module Frontend
  class SearchRunner
    attr_accessor :results, :results_count
    
    def initialize(query)
      @query = query
    end
    
    def run
      # Alle Sonderzeichen entfernen
      @query.gsub!(/[^a-zA-ZäöüÄÖÜ]+/, " ")
      
      # Kleinschreiben
      @query.downcase!
      
      # Der Hash results beinhaltet den jeweiligen Score für jedes Dokument (ID => Score)
      results = Hash.new(0)
      @query.split(" ").uniq.each do |word|
        postings = Frontend::Postings.new(word, load: true)
        
        blocks = postings.blocks
        if blocks.size > 0
          # TODO: Falls im ersten Block nicht alle relevanten Ergebnisse sind, weitere Blöcke laden...
          block = blocks[0]
          block.fetch
          block.entries.each do |frequency, occurences, id|
            corpus_count = 1.0 # TODO
            results[id] += Math.log( occurences*1.0 / corpus_count)
          end
        end
      end
      
      @results_count = results.size
      @results = results.sort_by{|doc, score| score}.reverse.first(10).map{|id, score| [Frontend::Metadata.fetch(id), score]}
    end
  end
end
