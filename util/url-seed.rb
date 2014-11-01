#!/usr/bin/env ruby
require_relative '../lib/crawler/crawler'

# Dieses Skript lädt einige Startpunkte für die Websuche
# Deutschsprachige Seiten:
$domains  = %w[de.wikipedia.org tagesanzeiger.ch srf.ch 20min.ch nzz.ch spiegel.de chip.de heise.de]
$domains += %w[focus.de blick.ch bluewin.ch blogspot.ch sbb.ch local.ch comparis.ch]
$domains += %w[gutefrage.net mozilla.org yahoo.de]

# Englischsprachige Seiten:
$domains += %w[en.wikipedia.org stackoverflow.com imdb.com forbes.com cnn.com bbc.com theguardian.com]


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

all_urls = $domains.map{|domain| fetch_urls(Common::URL.encoded("http://#{domain}/"))}.flatten

# URLs in Datenbank eintragen
all_urls.uniq.each_slice(50) do |urls|
  Crawler::Database.download_queue_insert(urls)
end
