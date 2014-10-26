module Crawler
  # Bestimmt die Häufigkeit von Worten im Dokument.
  class WordCounter
    def initialize(text)
      @text = text
    end
    
    def counts      
      # Ein Array aller vorkommenden kleingeschriebenen Wörter erzeugen,
      # Wörter werden gegebenenfalls auf 20 Zeichen Länge reduziert.
      words = @text.gsub(/[^a-zA-ZäöüÄÖÜ]+/, " ").downcase.split(" ").map{|word| word[0...20]}
      total_words = words.size
      
      # Häufigkeit der Wörter ermitteln
      count = Hash.new(0)
      words.each{|word| count[word] += 1}
      count
    end
  end
end
