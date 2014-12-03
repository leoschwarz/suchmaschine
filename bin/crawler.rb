#!/usr/bin/env ruby
require_relative '../lib/common/common.rb'
require_relative '../lib/crawler/crawler.rb'

if __FILE__ == $0
  Crawler::Client.new.launch
end
