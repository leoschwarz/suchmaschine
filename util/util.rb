# Um unnötige Widerholung von Code zu vermeiden hier eine Zusammenstellung der wichtigsten
# Methoden für die Skripts.

require_relative '../lib/common/config.rb'
require 'oj'

def update_line(x, width=80)
  print "\r#{x.ljust(width)}"
end
