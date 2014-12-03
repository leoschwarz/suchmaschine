#!/usr/bin/env ruby
require_relative '../lib/common/common.rb'
require_relative '../lib/frontend/frontend.rb'

if __FILE__ == $0
  Frontend::WebServer.run!
end
