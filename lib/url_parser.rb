module Crawler
  class URLParser
    def initialize(base, link)
      @base = base
      @link = link
    end
  
    def full_path
      part1 = URI(@base)
      begin
        part2 = URI(@link)
      rescue Exception => e
        begin
          part2 = URI(URI.encode(@link))
        rescue Exception => e
          # Falls tatsächlich eine schlechte URL in den Parser gerät, ist es am sichersten einfach nil zurückzugeben und dies zu ignorieren
          return nil
        end
      end
    
      scheme = part2.scheme
      if scheme != "http" and scheme != "https" and scheme != nil
        return nil
      end
    
      url = URI::join(part1, part2).to_s
      # remove #-part of url
      hash_index = url.index("#")
      unless hash_index.nil?
        url = url[0...hash_index]
      end
      url
    end
  end
end