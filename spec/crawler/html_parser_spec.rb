require 'spec_helper'

describe Crawler::HTMLParser do
  EXAMPLE_HTML = <<HTML
  <!DOCTYPE html>
  <html>
    <head>
      <title>Example page.</title>
    </head>
    <body>
      <p>Lorem ipsum dolor sit amet.</p>
      <p>Visit <a href="http://example.com">example</a> for free pizza.</p>
      <p>Check <a href="//example.com">another example</a> for even more free pizza.</p>
      <script> console.log("Scripts shouldn't be displayed for example.") </script>
      <!-- Comments neither for example. -->
      <p>Check <a href="example">relative example</a> for more information on relativity.</p>
    </body>
  </html>
HTML

  EXAMPLE_BASEURL = Common::URL.decoded('http://base.example.com/folder')

  it 'initializes' do
    Crawler::HTMLParser.new(EXAMPLE_BASEURL, EXAMPLE_HTML)
  end

  it 'extracts text' do
    parser = Crawler::HTMLParser.new(EXAMPLE_BASEURL, EXAMPLE_HTML)
    expect(parser.text).to eq('Example page. Lorem ipsum dolor sit amet. Visit example for free pizza. Check another example for even more free pizza. Check relative example for more information on relativity.')
  end

  it 'checks title presence' do
    parser = Crawler::HTMLParser.new(EXAMPLE_BASEURL, EXAMPLE_HTML)
    expect(parser.title_ok?).to be(true)
    parser = Crawler::HTMLParser.new(EXAMPLE_BASEURL, '
      <!DOCTYPE html>
      <html>
        <head></head>
        <body><p>Lorem ipsum dolor sit amet.</p></body>
      </html>')
    expect(parser.title_ok?).to be(false)
  end

  it 'default permissions' do
    parser = Crawler::HTMLParser.new(EXAMPLE_BASEURL, EXAMPLE_HTML)
    expect(parser.permissions).to eq({index: true, follow: true})
  end

  it 'parses permissions' do
    htmls = ['noindex', 'nofollow', 'noindex, nofollow', '']
    expected = [{index: false, follow: true},
                {index: true, follow: false},
                {index: false, follow: false},
                {index: true, follow: true}]

    (0..3).each do |test_index|
      html = "<!DOCTYPE html>
      <html>
        <head>
          <meta name='robots' content='#{htmls[test_index]}' />
          <title>Example page.</title>
        </head>
        <body><p>Lorem ipsum dolor sit amet.</p></body>
      </html>"
      parser = Crawler::HTMLParser.new(EXAMPLE_BASEURL, html)
      expect(parser.permissions).to eq(expected[test_index])
    end
  end

  it 'extracts links' do
    parser = Crawler::HTMLParser.new(EXAMPLE_BASEURL, EXAMPLE_HTML)
    expect(parser.links.size).to eq(3)
    expect(parser.links.map { |label, url| label }).to eq(['example', 'another example', 'relative example'])
  end

  it 'extracts links relatively' do
    parser = Crawler::HTMLParser.new(EXAMPLE_BASEURL, EXAMPLE_HTML)
    expect(parser.links.size).to eq(3)
    expect(parser.links.map { |label, url| url.decoded_url }).to eq(['http://example.com', 'http://example.com', 'http://base.example.com/example'])
  end
end
