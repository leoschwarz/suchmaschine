# Dieses Programm ladet die 1'000'000 meist frequentierten Seiten (gemäss Alexa Internet, Inc.) in den Index
# Auf dieser (nicht offiziellen) Seite gefunden: http://randolf.jorberg.de/2008/12/07/weihnachtsgeschenke-von-alexa-1-million-top-sites-csv-for-free/
require './bin/crawler.rb'
require 'tmpdir'

url = "http://s3.amazonaws.com/alexa-static/top-1m.csv.zip"

def insert_task
  EM::next_tick do 
    if $urls.length == 0
      EM.stop
    else
      Crawler::Task.insert($urls.shift).callback{
        insert_task()
      }
    end
  end
end

Dir.mktmpdir do |dir|
  puts "Download wird gestartet."
  `cd #{dir}; wget #{url} -O dl.zip`
  `cd #{dir}; unzip dl.zip`
  puts "Download abgeschlossen."
  
  $urls = []
  
  puts "Datei wird eingelesen."
  
  csv_file = File.new(File.join(dir, "top-1m.csv"))
  csv_file.each_line do |line|
    domain = line.split(",")[1].strip
    url    = "http://#{domain}/"
    $urls << url
  end
  csv_file.close
  csv_file = nil
  
  puts "Datei wurde eingelesen."
  puts "Daten werden in Datenbank eingetragen."
  
  EM::run do
    insert_task()
  end
  
  puts "Fertig. Die 1'000'000 meistbesuchten Seiten aus dem Alexa Index wurden in den Suchindex aufgenommen."
end


