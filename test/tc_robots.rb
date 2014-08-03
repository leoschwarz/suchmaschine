class TestRobots < Test::Unit::TestCase
  include EventMachine::TestHelper
  
  def setup
    file("test1.example.com", "01.txt")
    file("test2.example.com", "02.txt")
    file("test3.example.com", "03.txt")
    file("test4.example.com", "04.txt")
    file("test5.example.com", "05.txt")
    file("test6.example.com", "06.txt")
    file("test7.example.com", "07.txt")
    
    stub_request(:any, "test404.example.com/robots.txt").to_return(status: 404)
    stub_request(:any, "test500.example.com/robots.txt").to_return(status: 500)
  end
  
  def file(domain, file)
    stub_request(:any, "#{domain}/robots.txt").to_return(body: File.new("./test/assets/robots/#{file}"), status: 200)
  end
  
  def assert_robots_allowed(url, value, finish=true, user_agent=Crawler::USER_AGENT)
    em do 
      Crawler::RobotsParser.new(user_agent, false).allowed?(url).callback{|allowed|
        message = "Robots should #{value ? "" : "not"} be allowed for '#{url}'."
        assert(allowed==value, message)
        if finish then done end
      }.errback{
        raise
        if finish then done end
      }
    end
  end
  
  # Kommentare dürfen nicht berücksichtigt werden + Einfache disallow Funktionalität
  def test_01_comment
    assert_robots_allowed("http://test1.example.com", false)
  end
  
  # Unterverzeichnisse erben
  def test_02_inheritance
    assert_robots_allowed("http://test1.example.com/test", false)
  end
  
  # Ein späteres Allow erlaubt ein vorheriges Disallow
  def test_03_allow
    assert_robots_allowed("http://test2.example.com/test", true)
  end
  
  # Unterverzeichnisse erben
  def test_04_inheritance
    assert_robots_allowed("http://test2.example.com/test/subdirectory", true)
  end
  
  # User-agent: *
  def test_05_wildcard_user_agent
    assert_robots_allowed("http://test3.example.com/test", false)
  end
  
  # Verzeichnisse die nicht verboten oder erlaubt worden müssen erlaubt sein
  def test_06_default_value
    assert_robots_allowed("http://test3.example.com", true)
  end
  
  # User-agent, Allow, Disallow direktiven sollten nicht case-sensitive sein und auch ohne Leerzeichen zwischen dem Doppelpunkt und dem Wert funktionieren
  def test_07_formatting
    assert_robots_allowed("http://test4.example.com/news", true)
  end
  def test_08_formatting
    assert_robots_allowed("http://test4.example.com/test", false)
  end
  
  # Wildcards
  # Disallow: /test*/news
  def test_09_wildcards
    assert_robots_allowed("http://test5.example.com/test2/", true)
  end
  def test_10_wildcards
    assert_robots_allowed("http://test5.example.com/test44/news", false)
  end
  def test_11_wildcards
    assert_robots_allowed("http://test5.example.com/test/news", false)
  end
  def test_12_wildcards
    assert_robots_allowed("http://test5.example.com/tes/news", true)
  end
  
  # Fragezeichen
  # Disallow: /*?
  def test_13_questionmark
    assert_robots_allowed("http://test6.example.com/test", true)
  end
  def test_14_questionmark
    assert_robots_allowed("http://test6.example.com/test.php?", false)
  end
  def test_15_questionmark
    assert_robots_allowed("http://test6.example.com/test.php?page_id=15", false)
  end
  
  # Ende der Zeichenkette
  # Disallow: /*.mp3$
  def test_16_endofstring
    assert_robots_allowed("http://test7.example.com/reallybadsong.mp3", false)
  end
  def test_17_endofstring
    assert_robots_allowed("http://test7.example.com/reallybadsong.mp3-in-the-news-again.html", true)
  end
  
  # 404 -> alles erlaubt
  def test_18_http_404
    assert_robots_allowed("http://test404.example.com/news", true)
  end
  
  # 500 -> alles verboten
  def test_19_http_500
    assert_robots_allowed("http://test500.example.com/news", false)
  end
end