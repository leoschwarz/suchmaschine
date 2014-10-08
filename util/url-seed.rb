#!/usr/bin/env ruby
require 'open-uri'
require_relative '../bin/crawler.rb'

# Dieses Skript lädt einige Startpunkte für die Websuche
# Deutschsprachige Seiten:
domains  = %w[de.wikipedia.org tagesanzeiger.ch srf.ch 20min.ch nzz.ch spiegel.de chip.de heise.de]
domains += %w[focus.de blick.ch bluewin.ch blogspot.ch sbb.ch local.ch comparis.ch]

# Englischsprachige Seiten:
domains += %w[en.wikipedia.org stackoverflow.com imdb.com forbes.com]


# URLs für jede Seite laden
all_urls = []
domains.each do |domain|
  url = Common::URL.encoded "http://#{domain}/"
  parser = Crawler::HTMLParser.new(url, open(url.encoded).read)
  parser.links.each do |anchor, link_url|
    unless link_url.nil?
      # URL hinzufügen, falls der Domain Name aufgelistet wurde
      all_urls << link_url.stored if domains.include? link_url.domain_name
    end
  end
  puts "Gescannt: #{domain}"
end

# URLs in Datenbank eintragen
all_urls.uniq.each_slice(50) do |urls|
  Crawler::Database.download_queue_insert(urls)
end
