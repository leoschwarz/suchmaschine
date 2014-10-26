#!/usr/bin/env ruby
require_relative '../bin/crawler.rb'

# Dieses Skript lädt einige Startpunkte für die Websuche
# Deutschsprachige Seiten:
domains  = %w[de.wikipedia.org tagesanzeiger.ch srf.ch 20min.ch nzz.ch spiegel.de chip.de heise.de]
domains += %w[focus.de blick.ch bluewin.ch blogspot.ch sbb.ch local.ch comparis.ch]
domains += %w[gutefrage.net mozilla.org yahoo.de]

# Englischsprachige Seiten:
domains += %w[en.wikipedia.org stackoverflow.com imdb.com forbes.com cnn.com bbc.com theguardian.com]


# URLs für jede Seite laden
all_urls = []
domains.each do |domain|
  url = Common::URL.encoded "http://#{domain}/"
  download = Crawler::Download.new(url)
  
  if download.success?
    parser = Crawler::HTMLParser.new(url, download.response_body)
    parser.links.each do |anchor, link_url|
      unless link_url.nil?
        # URL hinzufügen, falls der Domain Name aufgelistet wurde
        all_urls << link_url.stored if domains.include? link_url.domain_name
      end
    end
    puts "[✓] #{url.decoded}"
  else
    puts "[✕] #{url.decoded}"
  end
end

# URLs in Datenbank eintragen
all_urls.uniq.each_slice(50) do |urls|
  Crawler::Database.download_queue_insert(urls)
end
