require 'json'
require 'inline'
require 'singleton'


=begin #=================================================================#
# Ergebnisse des Benchmarks: (3 Texte DE kompilieren) 14. September 2014 
# Ruby-Version:
#  39.820000   0.050000  39.870000 ( 39.926936)
# C-Version
#  21.830000   0.060000  21.890000 ( 21.906297)

# VORLAGE FÜR DEN C-CODE
def self.count_ngrams(_text)
  text = _text.gsub(/[^a-zA-ZäöüÄÖÜ']+/, "_")

  counter = {}
  (0...text.length-5).each do |i|
    ngram = text[i...i+5]
    if counter.has_key? ngram
      counter[ngram] += 1
    else
      counter[ngram]  = 1
    end
  end

  counter
end
=end #===================================================================#


module Crawler
  module LanguageDetection
    class Detector
      include Singleton
    
      def initialize
        load_language_data
      end
    
      def load_language_data
        _languages = Dir["data/language-detection/*"].map{|f| File.basename f}
        @languages = {}
        _languages.each do |language|
          @languages[language] = JSON.parse(File.read("data/language-detection/#{language}/count.json"))
        end
      end
    
      def detect(string)
        sample_ranks = LanguageDetection.rank_ngrams(string, @languages.first[1].size)
        scores       = {}
        @languages.each_pair do |language, language_data|
          scores[language] = 0
          sample_ranks.each_pair do |ngram, rank|
            deviation = nil
            if language_data.has_key? ngram
              scores[language] += (rank - language_data[ngram]).abs
            else
              scores[language] += language_data.size
            end
          end
        end
        
        scores
      end
    end
    
    # count_ngrams_c
    inline :C do |builder|
      builder.c_singleton <<-__INLINE__
        VALUE count_ngrams_c(VALUE text) {
          VALUE counter = rb_hash_new();
          VALUE ngram;
          int old_count, i, j;
          int length = RSTRING_LEN(text);
          for (i=0; i <= length-5; i++) {
            for (j=1; j<=5; j++) {
              ngram = rb_str_substr(text, i, j);
              if (RTEST(rb_hash_aref(counter, ngram))) {
                old_count = FIX2INT(rb_hash_aref(counter, ngram));
                rb_hash_aset(counter, ngram, INT2FIX(old_count+1));
              } else if (!NIL_P(ngram)) { /* ngram kann manchmal nil sein... */
                rb_hash_aset(counter, ngram, INT2FIX(1));
              }
            }
          }
        
          return counter;
        }      
      __INLINE__
    end
    
    def self.count_ngrams(_text)
      text = _text.gsub(/[^a-zA-ZäöüÄÖÜ']+/, "_")
      text = "_#{text}_"
      self.count_ngrams_c(text)
    end
  
    # Erzeugt einen Hash in dem jedes N-Gramm einem Rang zugewiesen wird. (Das häufigste = 0, Das seltenste = n-1)
    def self.rank_ngram_count(count, nmax)
      count.sort_by{|ngram,count| count}.reverse.each_with_index.map{|item, rank| [item[0], rank]}[0...nmax].to_h
    end
  
    def self.rank_ngrams(text, nmax)
      self.rank_ngram_count(self.count_ngrams(text), nmax)
    end
    
    def self.join_count_hashes(hash1, hash2)    
      hash2.each_pair do |key, value|
        if hash1.has_key? key
          hash1[key] += value
        else
          hash1[key]  = value
        end
      end
    end
  end
end


