require 'test/unit'
require './crawler.rb'

class TestURLParser < Test::Unit::TestCase
  BASE_URL1 = "http://example.com"
  BASE_URL2 = "http://example.com/news/"
  BASE_URL3 = "https://example.com/news"
  
  def test_absolute
    assert_equal("http://news.example.com", _relative_url("http://news.example.com"))
    assert_equal("https://news.example.com", _relative_url("https://news.example.com"))
  end
  
  def test_relative
    assert_equal("http://example.com/news", _relative_url("news"))
    assert_equal("http://example.com/news", _relative_url("/news"))
    assert_equal("http://example.com/news/all", _relative_url("all", 2))
    assert_equal("http://example.com/all", _relative_url("/all", 2))
  end
  
  def test_protocols
    assert_equal(nil, _relative_url("mailto:nick@example.com"))
    assert_equal(nil, _relative_url("ssh://rootuser@example.com"))
    assert_equal("http://example.net", _relative_url("//example.net"))
    assert_equal("https://example.net", _relative_url("//example.net", 3))
  end
  
  def test_hashsign
    assert_equal("http://example.com/news", _relative_url("news#chicken"))
    assert_equal("http://example.com", _relative_url("#chicken"))
  end
  
  def test_utf8
    assert_equal("http://example.com/Schwiz%C3%A4rch%C3%A4%C3%A4s", _relative_url("Schwizärchääs"))
    assert_equal("http://example.com/av%C3%A9c%20b%C3%A9eaucoup%20de%20faut%C3%A8s", _relative_url("avéc béeaucoup de fautès"))
  end
  
  
  private
  def _relative_url(url, n=1)
    if n == 1
      URLParser.new(BASE_URL1, url).full_path
    elsif n == 2
      URLParser.new(BASE_URL2, url).full_path
    elsif n == 3
      URLParser.new(BASE_URL3, url).full_path
    else
      throw "wrong n"
    end
  end
end