require_relative '../bin/crawler.rb'
require 'minitest/autorun'
require 'webmock/minitest'
require 'eventmachine'

ENV["LIGHTBLAZE_ENV"] = "test"

require_relative 'tc_url_parser.rb'
require_relative 'tc_robots.rb'
require_relative 'tc_html_parser.rb'
