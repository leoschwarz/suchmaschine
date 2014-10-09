#!/usr/bin/env ruby

#
# Dieses Hilfsprogramm bereitet die Daten, die später für die Spracherkennung benötigt werden, vor.
#

require 'json'
require './lib/crawler/language_detection'


def create_language_count(language)
  count = {}
  Dir["data/language-detection/#{language}/*.txt"].each do |file|
    puts "Zählen von #{file} wurde begonnen."
    count = Crawler::LanguageDetection.join_count_hashes(count, Crawler::LanguageDetection.count_ngrams(File.read(file)))
    puts "Zählen von #{file} wurde beendet."
    return count
  end
  count
end

def compile_language(language, nmax = 500)
  count = create_language_count(language)
  data  = Crawler::LanguageDetection.rank_ngram_count(count, nmax)

  File.open("data/language-detection/#{language}/count.json", "w") do |file|
    file.write(JSON.dump data)
  end
end


if __FILE__ == $0
  languages = Dir["data/language-detection/*"].map{|f| File.basename f}
  languages.each do |language|
    puts "Start: #{language}"
    start_time = Time.now

    compile_language(language, 500)

    puts "Ende:  #{language} (Dauer: #{(Time.now-start_time).round(1)}s)\n"
  end
end
