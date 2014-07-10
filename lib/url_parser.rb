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
      part2 = URI(URI.encode(@link))
    end
    
    scheme = part2.scheme
    if scheme != "http" and scheme != "https" and scheme != nil
      return nil
    end
    
    url = URI::join(part1, part2).to_s
    # remove #-part of url
    url = url.split("#").first
  end
end