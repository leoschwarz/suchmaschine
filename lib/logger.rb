module Crawler
  class Logger
    def initialize
      ok = false
      i = 0
      while not ok
        i += 1
        num = i.to_s.rjust(5, "0")
        @filename = "./log/"+(Time.now.strftime "%Y-%m-%d-#{num}.csv")
        ok = true unless File.exists? @filename
      end
      
      @counts = {success: 0, failure: 0, not_allowed: 0, not_ready: 0}
      @t = 0
      file = File.open(@filename, "w")
      file.write("Zeit,Erfolge,Fehlschläge,Verboten,Übersprungen\n")
      file.close
      @start_time = Time.now
    end
    
    # schreibt eine weitere Zeile in die Log Datei
    def write
      file = File.open(@filename, "a")
      file.write( serialize )
    end
    
    def register(type)
      @counts[type] += 1
    end
    
    private
    def serialize
      t = (Time.now - @start_time).round
      s = "#{t},#{@counts[:success]},#{@counts[:failure]},#{@counts[:not_allowed]},#{@counts[:not_ready]}\n"
    end
  end
end
