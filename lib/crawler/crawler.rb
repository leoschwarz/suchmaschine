############################################################################################
# Diese Datei lädt das Crawler Modul                                                       #
############################################################################################
module Crawler
  include Common::Database
end

require_relative './client.rb'
require_relative './download.rb'
require_relative './html_parser.rb'
require_relative './robotstxt.rb'
require_relative './task.rb'
require_relative './word_counter.rb'
