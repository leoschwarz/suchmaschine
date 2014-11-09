#!/usr/bin/env ruby
# Dieses Skript lädt einige Startpunkte für die Websuche
require_relative '../lib/crawler/crawler'
require 'oj'

# Deutschsprachige Seiten:
$domains  = %w[de.wikipedia.org tagesanzeiger.ch srf.ch 20min.ch nzz.ch spiegel.de chip.de heise.de]
$domains += %w[focus.de blick.ch bluewin.ch blogspot.ch sbb.ch local.ch comparis.ch]
$domains += %w[gutefrage.net mozilla.org yahoo.de]

# Englischsprachige Seiten:
$domains += %w[en.wikipedia.org stackoverflow.com imdb.com forbes.com cnn.com bbc.com theguardian.com]

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
    parser.links.map{|anchor,link| link.stored}
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
all_urls = $domains.map{|domain| fetch_urls(Common::URL.encoded("http://#{domain}/"))}.flatten
insert_urls all_urls

# URLs in die CACHE-Datei schreiben.
File.open(CACHE_FILE, "w") do |file|
  file.write(Oj.dump(all_urls))
end
