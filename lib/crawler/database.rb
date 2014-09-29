module Crawler
  class Database
    def self.queue_insert(urls)
      self._run("QUEUE_INSERT\t"+urls.join("\t"))
    end
    
    def self.queue_fetch()
      Task.new(URL.stored self._run("QUEUE_FETCH")[0])
    end
    
    # TODO LinkData
    
    def self.document_set(url, document)
      self._run("DOCUMENT_SET\t#{url}\t#{document}")
    end
    
    def self.document_get(urls)
      self._run("DOCUMENT_GET\t"+urls.join("\t"))
    end
    
    private
    def self._run(query)
      begin
        connection = TCPSocket.new("127.0.0.1", 2051)
        connection.write(query)
        response   = connection.recv(10000000)
        connection.close
        
        unless response.nil? or response.empty?
          return response.split("\t")
        end
      rescue Exception
        # TODO
      end
      nil
    end
  end
end