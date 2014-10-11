# TODO : Noch nicht richtig Threadsicher.
#        Wahrscheinlich wird es nötig sein, eine Queue einzuführen um auf die Streams zu schreiben.

module Common
  class LoggerLevel
    include Comparable
    attr_accessor :name, :value

    def initialize(name, value)
      @name = name
      @value = value # Wert für Vergleiche. Der kleinste Wert = Tiefste Priorität
    end

    def <=>(other)
      self.value <=> other.value
    end
  end
  
  class Logger
    ERROR   = LoggerLevel.new("FEHL", 0).freeze
    WARNING = LoggerLevel.new("WARN", 0).freeze
    INFO    = LoggerLevel.new("INFO", 0).freeze

    def initialize(options={labels: {}})
      @outputs  = []
      @labels   = options[:labels]
      @progress = OrderedHash.new
    end

    # Ermöglicht das setzen und lesen der Fortschrittszähler.
    attr_accessor :progress

    # Fügt einen neuen Ausgabe-Stream hinzu der alle Nachrichten ab min_level aufzeichnet.
    def add_output(stream, min_level)
      @outputs << {stream: stream, min_level: min_level}
    end

    # Zeigt die Beschriftungen für die Fortschrittszähler an.
    def log_progress_labels(level=INFO)
      self.log_line(@progress.keys.map{|name| _label(name)}.join("\t"), level)
    end

    # Zeigt den Fortschritt an.
    def log_progress(level=INFO)
      # Eventuelle Procs ausführen
      evaluated_values = @progress.values.map do |value|
        if value.class == Proc
          value.call(self)
        else
          value
        end
      end

      # Ausgeben
      self.log_line(evaluated_values.join("\t"), level)
    end

    # Gibt eine Zeile aus.
    def log_line(text, level)
      line = "[#{level.name}][#{Time.now.strftime "%d-%m-%y %H:%M:%S.%L"}] #{text}"
      @outputs.each do |output|
        if output[:min_level] <= level
          output[:stream].puts line
        end
      end
    end
    
    # Gibt mehrere Zeilen aus.
    def log_lines(lines, level)
      label       = "[#{level.name}][#{Time.now.strftime "%d-%m-%y %H:%M:%S.%L"}] "
      first_line  = label + lines.first
      other_lines = lines[1...-1].map{|line| " "*label.size + line}
      text = other_lines.insert(0, first_line).join("\n")
      @outputs.each do |output|
        if output[:min_level] <= level
          output[:stream].puts text
        end
      end
    end
    
    def log_message(msg, level)
      if msg.class == Array
        log_lines(msg, level)
      elsif msg.include?("\n")
        log_lines(msg.split("\n"), level)
      else
        log_line(msg)
      end
    end

    def log_error(error)
      self.log_message(error, ERROR)
    end

    def log_warning(warning)
      self.log_message(warning, WARNING)
    end

    def log_info(info)
      self.log_message(info, INFO)
    end

    # Gibt die Anzahl Sekunden zurück die seit dem ersten Aufruf dieser Methode verstrichen sind.
    def elapsed_time
      @started_at = Time.now.to_i if @started_at.nil?
      Time.now.to_i - @started_at
    end

    private
    def _label(str)
      return @labels[str] if @labels.has_key?(str)
      str
    end
  end
end
