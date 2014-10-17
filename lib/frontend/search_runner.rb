module Frontend
  class SearchRunner
    def self.get_results(query)
      # Alle Sonderzeichen entfernen
      query.gsub!(/[^a-zA-ZäöüÄÖÜ]+/, " ")
      
      # Kleinschreiben
      query.downcase!
      
      # Für jedes Wort den Reverse Index laden:
      sets = []
      query.split(" ").uniq.each do |word|
        sets << Database.index_get(word)
      end
      
      # Schnittmenge bilden
      results = sets.pop
      sets.each do |set|
        results = results & set
      end
      
      results
    end
  end
end
