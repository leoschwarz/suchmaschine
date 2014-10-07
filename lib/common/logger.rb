module Common
  class Logger
    attr_accessor :started_at
    
    # variables: Array mit Namen der Werte die angezeigt werden sollen.
    # interval:  Anzahl der Sekunden zwischen einzelnen Ausgaben von start_display.
    # labels:    Ein Hash mit Ersatznamen für die Variabeln.
    def initialize(options={})
      default_options = {variables: [], labels: {}, interval: 5}
      options         = default_options.merge(options)
      @labels         = options[:labels]
      @variables      = options[:variables]
      @values         = {}
      @variables.each{|name| @values[name] = 0}
    end
    
    # Wert für eine Anzeigevariable direkt setzen.
    # Falls der Wert eine Proc-Instanz ist, wird diese beim Anzeigen aufgerufen.
    def set(name, value)
      @values[name] = value
    end
    
    # Wert für eine Anzeigevariable um Wert amount erhöhen.
    def increase(name, amount)
      @values[name] += amount
    end
    
    def start_display(output = $stdout, extra_thread=true)
      if extra_thread
        return Thread.new{ start_display(output, false) }
      end
      
      # Header anzeigen:
      output.puts @variables.map{|name| if @labels.has_key?(name) then @labels[name] else name end}.join("\t")
      
      # Zeitpunkt festhalten:
      @started_at = Time.now
      
      loop do
        # Zeilen anzeigen:
        evaluated_values = @variables.map do |name|
          if @values[name].class == Proc
            @values[name].call(self).to_s
          else
            @values[name].to_s
          end
        end
        output.puts evaluated_values.join("\t")
        
        sleep 5
      end
    end
  end
end
