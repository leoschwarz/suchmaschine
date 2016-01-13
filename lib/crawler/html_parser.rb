# Copyright (c) 2014-2016 Leonardo Schwarz <mail@leoschwarz.com>
#
# This file is part of BreakSearch.
#
# BreakSearch is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License version 3
# as published by the Free Software Foundation.
#
# BreakSearch is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with BreakSearch. If not, see <http://www.gnu.org/licenses/>.

require 'oga'

module Crawler
  # The HTMLParser extracts all data relevant to us from the raw HTML document.
  class HTMLParser
    # @return [String] Title of the document.
    attr_reader :title

    # @return [String] Text of the document. This includes the title and the concatenation of
    #                  all elements inside the document's body.
    attr_reader :text

    # @return [Array[String, URL]] Links (in anchor, url pairs) that may be followed (if any)
    attr_reader :links

    # @return [Hash] Returns a hash with :index and :follow key indicating the document level
    #                robots permissions. Defaults to liberal permissions if nothing is specified.
    attr_reader :permissions

    # Initializes a new parser instance and parses the document.
    # @param base_url [URL] The URL of the document that will be used to resolve relative links.
    # @param html [String] The raw HTML to be parsed.
    def initialize(base_url, html)
      # Initialize fields.
      @base_url = base_url
      @doc = Oga.parse_html(html)

      # Parse HTML.
      @title = extract_title
      @permissions = extract_permissions
      @links = extract_links if permissions[:follow]
      if permissions[:index]
        remove_invisible_items
        @text = extract_text
      else
        @text = ''
      end
    end

    # Checks whether the document's title is alright.
    # @return [Boolean]
    def title_ok?
      @title != nil
    end

    private
    # Removes all multiple occurrences of whitespaces as-well as any leading and trailing ones.
    # @param text [String] The string to be cleaned up.
    # @return [String] The cleaned up string.
    def clean_text(text)
      text.gsub(/\s+/, ' ').strip
    end

    # Removes all scripts, styles and comments from the document.
    # @return [nil]
    def remove_invisible_items
      @doc.xpath('//script').each { |el| el.remove }
      @doc.xpath('//style').each { |el| el.remove }
      @doc.xpath('//comment()').remove
    end

    # Extracts the title of the document.
    # @return [String, nil] Title of the document trimmed to maximally 100 characters. nil if there is no title.
    def extract_title
      title_tag = @doc.xpath('//title')[0]
      return nil if title_tag.nil?
      return nil if (title = clean_text(title_tag.text)).size < 1
      title[0..100]
    end

    # Extracts robot permissions from the document.
    # Default values will be returned if nothing is found in the document.
    # @return [Hash]
    def extract_permissions
      result = {index: true, follow: true}
      if (metatag_robots = @doc.at_xpath("//meta[@name='robots']/@content")) != nil
        data = metatag_robots.text.downcase
        result[:index] = !data.include?('noindex')
        result[:follow] = !data.include?('nofollow')
      end
      result
    end

    # Extracts all valid links from the document that may be followed.
    # @return [Array]
    def extract_links
      links = []
      @doc.xpath('//a[@href]').each do |link|
        if link.get('rel').nil? or not link.get('rel').include?('nofollow')
          url = @base_url.join_with(link.get('href'))
          links << [clean_text(link.text), url] unless url.nil?
        end
      end
      links
    end

    # Extracts the text body of the document.
    # @return [String]
    def extract_text
      clean_text @doc.children.map(&:text).join('')
    end
  end
end
