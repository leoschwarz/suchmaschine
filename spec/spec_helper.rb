# Helfer laden.
require_relative './helpers/tempfile_helper.rb'
require_relative './helpers/assets_helper.rb'
RSpec.configure do |c|
  c.extend TempfileHelper
  c.extend AssetsHelper
end

# Starte Testabdeckungs-Messung.
require 'simplecov'
SimpleCov.start{ add_filter "/spec/" }

# Zu testenden Code laden.
require_relative '../lib/common/common.rb'
require_relative '../lib/crawler/crawler.rb'
require_relative '../lib/database/database.rb'
require_relative '../lib/frontend/frontend.rb'
require_relative '../lib/indexer/indexer.rb'
