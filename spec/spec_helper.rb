# Load helpers.
require_relative './helpers/tempfile_helper.rb'

# Load code coverage monitoring.
require 'simplecov'
SimpleCov.start{ add_filter "/spec/" }

# Load code to be tested.
require_relative '../lib/common/common.rb'
require_relative '../lib/crawler/crawler.rb'
require_relative '../lib/database/database.rb'
require_relative '../lib/frontend/frontend.rb'
require_relative '../lib/indexer/indexer.rb'
