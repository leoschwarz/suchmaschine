class HTMLParser
  def initialize(task, html)
    @task = task
    @html = html
  end
  
  def links
    res = []
    doc = Nokogiri::HTML(@html)
    doc.xpath('//a[@href]').each do |link|
      if link['rel'] != "nofollow"
        u = _clean_url(link['href'])
        res << u unless u.nil?
      end
    end
    res
  end
  
  private
  def _clean_url(url)
    url = URLParser.new(@task.encoded_url, url).full_path
    if $robots.allowed? url
      return url
    else
      return nil
    end
  end
end