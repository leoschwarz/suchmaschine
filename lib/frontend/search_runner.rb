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
        postings = Common::PostingsFile.new(word)
        postings_metadata = Common::PostingsMetadataFile.new(word)
        
        if postings.exist?
          postings_metadata.read
          corpus_count = postings_metadata.total_occurences
        
          postings.read_entries().each do |docid, count|
            results[docid] += Math.log( count*1.0 / corpus_count )
          end
        end
      end
      
      @results_count = results.size
      @results = results.sort_by{|doc, score| score}.reverse.first(10).map{|doc, score| [Common::DatabaseClient::Metadata.open(doc, false), score]}
    end
  end
end
