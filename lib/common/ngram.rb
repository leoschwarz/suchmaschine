require 'inline'

module Common
  # Ermöglich das effiziente generieren von n-Grammen
  class NGram
    # count_ngrams_c
    inline :C do |builder|
      builder.c_singleton <<-C
      // text:       Der gepaddte String dessen n-Gramme gezählt werden sollen.
      // ngram_size: Die länge der jeweiligen n-Gramme
      VALUE count_ngrams_c(VALUE text, VALUE rb_ngram_size) {
        VALUE counter = rb_hash_new();
        VALUE ngram;
        int old_count, i;
        int length = RSTRING_LEN(text);
        int ngram_size = FIX2INT(rb_ngram_size);
        for (i=0; i <= length-ngram_size; i++) {
          ngram = rb_str_substr(text, i, ngram_size);
          if (RTEST(rb_hash_aref(counter, ngram))) {
            old_count = FIX2INT(rb_hash_aref(counter, ngram));
            rb_hash_aset(counter, ngram, INT2FIX(old_count+1));
          } else if (!NIL_P(ngram)) { /* ngram kann manchmal nil sein... */
            rb_hash_aset(counter, ngram, INT2FIX(1));
          }
        }
      
        return counter;
      }
      C
    end
    
    def self.count_ngrams(_text, ngram_size)
      separator = "_"*(ngram_size-1)
      text = _text.gsub(/[^a-zA-ZäöüÄÖÜ']+/, separator)
      text = "#{separator}#{text}#{separator}"
      self.count_ngrams_c(text, ngram_size)
    end
  end
end