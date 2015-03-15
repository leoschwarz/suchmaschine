#!/usr/bin/env ruby
############################################################################################
# Dieses Skript lädt die spezifizierten Startpunkte in die Datenbank.                      #
# Hierfür wird jeweils eine Anfrage des Stammverzeichnis des Hosts durchgeführt, und alle  #
# Links der jeweiligen Seite eingefügt.                                                    #
#                                                                                          #
# Dieses Programm führt die Datenbankoperationen über das Client-Interface des Crawlers    #
# aus, weshalb der Datenbankserver gestartet sein muss, bevor das Skript gestartet wird.   #
############################################################################################
require_relative '../lib/crawler/crawler'
require 'oj'
require 'yaml'

# Die Startpunkte aus der Konfigurationsdatei laden.
path = File.join(File.dirname(__FILE__), "..", "config", "starting_points.yml")
$domains = YAML.load(File.read(path))

# Funktion um die URLs zu speichern.
def insert_urls(urls)
  urls.uniq.each_slice(50) do |_urls|
    Crawler::Database.download_queue_insert(_urls)
  end
end


# Überprüfen ob eine Cachedatei existiert
CACHE_FILE = File.join(File.dirname(__FILE__), "..", "tmp", "url-seed.json")
if File.exist? CACHE_FILE
  puts "URLs werden aus der CACHE-Datei geladen..."
  urls = Oj.load(File.read(CACHE_FILE))
  insert_urls(urls)
  Kernel.exit
end

# URLs für jede Seite laden
def fetch_urls(url, retries=3)
  download = Crawler::Download.new(url)
  if download.success?
    puts "[✓] #{url.decoded}"
    parser = Crawler::HTMLParser.new(url, download.response_body)
    parser.links.map{|anchor,link| link.remove_fragment_identifier; link.stored}
  else
    if retries > 0 and not download.redirect_url.nil?
      fetch_urls(download.redirect_url, retries-1)
    else
      puts "[✕] #{url.decoded}"
      []
    end
  end
end

# URLs in Datenbank speichern
all_urls = $domains.map{|domain| fetch_urls(Common::URL.encoded("http://#{domain}/"))}
insert_urls(all_urls.flatten)

# URLs in die CACHE-Datei schreiben.
File.open(CACHE_FILE, "w") do |file|
  file.write(Oj.dump(all_urls))
end
