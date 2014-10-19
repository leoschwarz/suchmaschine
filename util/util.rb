# Um unnötige Widerholung von Code zu vermeiden hier eine Zusammenstellung der wichtigsten
# Methoden für die Skripts.

require_relative '../lib/common/config.rb'
require 'lz4-ruby'
require 'oj'

def update_line(x, width=80)
  print "\r#{x.lpad(width)}"
end

def rewrite_file(path)
  result = yield(File.read path)
  unless result == false
    File.open(path, "w") do |file|
      file.write(result)
    end
  end
end

def rewrite_json(path)
  rewrite_file(path) do |raw|
    result = yield(Oj.load(LZ4.uncompress(raw)))
    if result == false
      false
    else
      LZ4.compress(Oj.dump(result))
    end
  end
end
