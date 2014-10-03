module Crawler
  class Database
    def self.queue_insert(urls)
      self._run("QUEUE_INSERT\t"+urls.join("\t"))
    end
    
    def self.queue_fetch()
      Task.new(URL.stored self._run("QUEUE_FETCH", false))
    end
    
    def self.cache_set(key, value)
      self._run("CACHE_SET\t#{key}\t#{value}")
    end
    
    def self.cache_get(key)
      self._run("CACHE_GET\t"+key, false)
    end
    
    def self.document_set(url, document)
      self._run("DOCUMENT_SET\t#{url}\t#{document}")
    end
    
    def self.document_get(urls)
      self._run("DOCUMENT_GET\t"+urls.join("\t"))
    end
    
    def self.document_info_set(url, docinfo)
      self._run("DOCUMENT_INFO_SET\t#{url}\t#{docinfo}")
    end
    
    def self.document_info_get(url)
      self._run("DOCUMENT_INFO_GET\t#{url}", false)
    end
    
    private
    def self._run(query, split_results=true)
      begin
        connection = TCPSocket.new("127.0.0.1", 2051)
        connection.puts(query)
        response   = connection.gets.strip
        connection.close
        
        unless response.nil? or response.empty?
          if split_results
            return response.split("\t")
          else
            return response
          end
        end
      rescue Exception
        # TODO
      end
      nil
    end
  end
end