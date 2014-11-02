require 'lz4-ruby'

module Indexer
  class PostingsTmp
    def initialize(word)
      @word
      @items = []
    end
    
    def add(hash, count)
      write if @items.size > 200
      @items << [hash, count]
    end
    
    def write
      Common::PostingsFile.new(File.join(Config.paths.index_tmp, "word:#{@word}"), true).write_entries(@items)
      @items.clear
    end
    
    def removed_from_cache
      write
    end
  end
  
  class Task
    def initialize(hash, metadata, postings_tmps)
      @hash     = hash
      @metadata = metadata
      @postings_tmps = postings_tmps
    end

    # Eine neue Aufgabe laden.
    def self.load(hash, postings_tmps)
      metadata = Indexer::Metadata.deserialize(LZ4.uncompress(File.read(Config.paths.metadata + hash)))
      self.new(hash, metadata, postings_tmps)
    end

    # Die Aufgabe bearbeiten.
    def run
      @metadata.word_counts.each_pair do |word, count|
        if @postings_tmps.include?(word)
          postings_tmp = @postings_tmps[word]
        else
          postings_tmp = PostingsTmp.new(word)
          @postings_tmps[word] = postings_tmp
        end
        postings_tmp.add(@hash, count)
      end
    end
  end
end
