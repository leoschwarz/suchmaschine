module Crawler
  class RobotsTXTParser
    attr_accessor :domain, :cache_item
    def initialize(domain, robot_name)
      @domain     = domain
      @robot_name = robot_name
      load
    end

    def load
      @cache_item = RobotsTXTCacheItem.load(@domain)
      if @cache_item.status != :ok
        begin
          # Download der robots.txt Datei
          url = Common::URL.encoded "http://#{@domain}/robots.txt"
          download = Crawler::Download.new(url)
          c = download.status[0]

          if c == "2"
            @cache_item.rules = parse(download.response_body)
            @cache_item.set_valid_for(:default)
          elsif c == "3" or c == "5"
            @cache_item.rules = [[:disallow, "/"]]
            @cache_item.set_valid_for(30)
          elsif c == "4"
            @cache_item.rules = []
            @cache_item.set_valid_for(:default)
          end

          @cache_item.save
        rescue => e
          raise e
          # TODO: Falls keine Probleme entstehen, einfach weglassen...
          @cache_item.rules = [[:disallow, "/"]]
          @cache_item.set_valid_for(30)
          @cache_item.save
        end
      end

    end

    def allowed?(path)
      allowed = true
      explicitely_allowed = false

      if @cache_item.nil?
        raise "Cache Item was not loaded."
      end

      @cache_item.rules.each do |rule|
        if not /^(#{rule[1]})/.match(path).nil?
          if rule[0] == :disallow
            allowed = false
          elsif rule[0] == :allow
            explicitely_allowed = true
          end
        end
      end

      explicitely_allowed || allowed
    end

    def parse(txt)
      groups = [] # items of form: [["agent1", "agent2"], [[:allow, "http://bla.example.com"], [:disallow, "http://example.com"]]]
      group_open = nil

      txt.lines.each do |line|
        line.gsub!(/#.*/, "")
        line.strip!

        match = /([-a-zA-Z]+):[ ]?(.*)$/.match(line)
        if not match.nil?
          key = match[1].strip
          value = match[2].strip

          if key.downcase == "user-agent"
            if group_open
              groups.last[0] << value
            else
              group_open = true
              groups << [[value],[]]
            end
          elsif key.downcase == "disallow"
            if not group_open.nil?
              group_open = false
              groups.last[1] << [:disallow, _convert_to_regex_string(value)] unless value.empty?
            end
          elsif key.downcase == "allow"
            if not group_open.nil?
              group_open = false
              groups.last[1] << [:allow, _convert_to_regex_string(value)]
            end
          end
        end
      end

      group_unspecified = []
      groups.each do |group|
        if group[0].include? @robot_name
          return group[1]
        elsif group[0].include? "*"
          group_unspecified = group[1]
        end
      end

      return group_unspecified
    end

    private
    # TODO: Dies macht noch immer Probleme
    def _convert_to_regex_string(value)
      s = Regexp.quote(value)
      s.gsub!(/\\\*/, "(.*)")
      s.gsub!(/\\\$/, "$")
      s
    end
  end
end
