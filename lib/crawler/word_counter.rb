############################################################################################
# Der Wortzähler leistet bereits Vorarbeit für den Indexierer, indem die Anzahl eines      #
# jeden Wortes in einer Zeichenkette ausgezählt wird.                                      #
############################################################################################
module Crawler
  class WordCounter
    def initialize(text)
      @text = text
    end

    def counts
      # Ein Array aller vorkommenden kleingeschriebenen Wörter erzeugen,
      # Wörter werden gegebenenfalls auf 20 Zeichen Länge reduziert.
      @text.gsub!(/[^a-zA-ZäöüÄÖÜ]+/, " ")
      words = @text.downcase.split(" ").map{|word| word[0...20]}
      total_words = words.size

      # Häufigkeit der Wörter ermitteln
      count = Hash.new(0)
      words.each{|word| count[word] += 1}
      count
    end
  end
end
