module Indexer
  class IndexTmpFile
    def initialize(word)
      @word = word
    end
    
    # pairs: Array bestehend aus Arrays in Form: [0]=Dokument, [1]=Zeile
    def insert(pairs)
      File.open(path, "a") do |file|
        file.puts pairs.map{|pair| pair.join(":")}.join("\n")
      end
    end
    
    def path
      "/mnt/sdb/suchmaschine/indextmp/word:#{@word}"
    end
  end
end
