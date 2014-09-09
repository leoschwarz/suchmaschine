module Crawler
  module TaskState
    NEW = "0"
    SUCCESS = "1"
    FAILURE = "2"
  end
  
  # @stored_url -> URL die in der Datenbank gespeichert wird. Ohne HTTP/HTTPs Schema, aber mit dekodierten Sonderzeichen
  # @encoded_url -> URL mit kodierten Sonderzeichen (Beispiel: http://de.wikipedia.org/wiki/K%C3%A4se)
  # @decoded_url -> URL mit dekodierten Sonderzeichen, also ein UTF-8 string (Beispiel: http://de.wikipedia.org/wiki/Käse)
  
  class Task
    attr_reader :state, :done_at
  
    def initialize(stored_url, state=TaskState::NEW, done_at=nil)
      @stored_url = stored_url
      @state = state
      @done_at = done_at
    end
    
    def stored_url
      @stored_url
    end
    
    def encoded_url
      @_encoded_url ||= URI.encode decoded_url
    end
    
    def decoded_url
      @_decoded_url ||= "http://#{@stored_url}"
    end
    
    # Getter für den Domain namen der url
    def domain_name
      Domain.domain_name_of(encoded_url)
    end
    
    # Markiert den Task in der Datenbank als erledigt
    def mark_done
      TaskQueue.set_states([stored_url, TaskState::SUCCESS])
    end
    
    # Markiet als verboten (wegen robots.txt)
    def mark_disallowed
      TaskQueue.set_states([stored_url, TaskState::FAILURE])
    end
  
    # TODO Dies ist nur eine provisorische "Lösung"
    def store_result(html)
      require 'digest/md5'
      filename = "./cache/html/#{Digest::MD5.hexdigest(decoded_url)}"
      f = open(filename, "w")
      f.write(html)
      f.close
      mark_done
    end
    
    # Ruft ein callback auf mit einem der Werte:
    # :ok -> alles in Ordnung
    # :not_ready -> es muss noch gewartet werden
    # :not_allowed -> robots.txt verbietet das crawlen
    def get_state
      if RobotsParser.allowed?(encoded_url)
        last_visited = Database.redis.get("domain.lastvisited.#{domain_name}").to_f
        if (Time.now.to_f - last_visited) > Crawler.config.crawl_delay
          return :ok
        else
          return :not_ready
        end
      else
        return :not_allowed
      end
    end
    
    def execute
      download = Crawler::Download.new(encoded_url)
      Database.redis.set("domain.lastvisited.#{domain_name}", Time.now.to_f.to_s)
      
      if download.success?
        if download.response_header["location"].nil?
          store_result(download.response_body)
          parser = HTMLParser.new(encoded_url, download.response_body)
          Task.insert(parser.get_links)
        else
          url = URLParser.new(encoded_url, download.response_header["location"]).full_path
          Task.insert([url])
        end
        
        return true
      else
        return false
      end
      
      mark_done
    end
    
    # Fügt neue URLs der Datenbank hinzu.
    # Im Falle, dass URLs bereits existiert, wird deren Priorität erhöht.
    def self.insert(encoded_urls)
      urls = encoded_urls.map{|url| _prepare_url_for_insert(url)}.select{|url| not url.nil?}
      TaskQueue.insert_tasks(urls)
    end
    
    private
    # Alle URLs sollen in ein einheitliches Format umgewandelt werden.
    # - Das Schema wird von den URLs entfernt. (http://www.example.com -> www.example.com)
    # - Der Fragment Identifier wird entfernt. (example.com/index.html#news -> example.com/index.html)
    def self._prepare_url_for_insert(encoded_url)
      # Überprüfen ob nil
      return nil if encoded_url.nil?
      decoded_url = URI.decode encoded_url
      
      # Länge überprüfen
      return nil if decoded_url.length > 512
      
      # Fragment Identifier wurde bereits von URLParser entfernt.
      
      # Schema entfernen
      # Siehe: http://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
      decoded_url.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').gsub(%r{^https?://}, "")
    end
  end
end