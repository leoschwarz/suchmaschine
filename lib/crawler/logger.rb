module Crawler
  class Logger
    def initialize(print_progress = false)
      @start_time = Time.now
      @counts = {success: 0, failure: 0, not_allowed: 0, not_ready: 0}
      @file = File.open(get_free_filename, "w")
      @file.write("Zeit,Erfolge,Fehlschläge,Verboten,Übersprungen\n")
      
      @print_progress = print_progress
      if @print_progress
        @print_fieldnames = ["Zeit", "Erfolge", "Fehlschläge", "Verboten", "Übersprungen"]
        puts @print_fieldnames.join(" ")
      end
    end
    
    # Schreibt eine Zeile in die Log Datei und gibt sie falls nötig auch auf $stdout aus.
    def write
      @file.write(serialize)
      
      if @print_progress
        time = (Time.now - @start_time).round
        puts [
          time.to_s.rjust(@print_fieldnames[0].length, " "),
          @counts[:success].to_s.rjust(@print_fieldnames[1].length, " "),
          @counts[:failure].to_s.rjust(@print_fieldnames[2].length, " "),
          @counts[:not_allowed].to_s.rjust(@print_fieldnames[3].length, " "),
          @counts[:not_ready].to_s.rjust(@print_fieldnames[4].length, " ")
        ].join(" ")
      end
    end
    
    # Erhöht den Zähler für einen Ergebnisstyp
    def register(type)
      @counts[type] += 1
    end
    
    private
    def serialize
      time = (Time.now - @start_time).round
      "#{time},#{@counts[:success]},#{@counts[:failure]},#{@counts[:not_allowed]},#{@counts[:not_ready]}\n"
    end
    
    def get_free_filename
      counter = 0
      loop do
        counter += 1
        counter_s = counter.to_s.rjust(5, "0")
        filename = "./log/"+(Time.now.strftime "%Y-%m-%d-#{counter_s}.csv")
        return filename unless File.exists? filename
      end
    end
  end
end
