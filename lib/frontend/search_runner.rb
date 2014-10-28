module Frontend
  class SearchRunner
    def self.get_results(query)
      # Alle Sonderzeichen entfernen
      query.gsub!(/[^a-zA-ZäöüÄÖÜ]+/, " ")
      
      # Kleinschreiben
      query.downcase!
      
      # Der Hash results beinhaltet den jeweiligen Score für jedes Dokument (ID => Score)
      results = Hash.new(0)
      query.split(" ").uniq.each do |word|
        postings = Common::PostingsFile.new(word)
        postings_metadata = Common::PostingsMetadataFile.new(word)
        
        postings_metadata.read
        corpus_count = postings_metadata.total_occurences
        
        postings.read_entries().each do |docid, count|
          results[docid] += Math.log( count*1.0 / corpus_count )
        end
      end
      
      results.sort_by{|doc, score|}.first(10)
    end
  end
end
