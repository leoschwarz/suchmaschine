module Common
  class Logger
    attr_accessor :started_at

    # variables: Array mit Namen der Werte die angezeigt werden sollen.
    # labels:    Ein Hash mit Ersatznamen für die Variabeln.
    # outputs:   Array mit IO Objekten auf die die Ausgabe geschrieben werden soll.
    #            Diese Objekte können auch mittels add_output hinzugefügt werden.
    def initialize(options={})
      default_options = {variables: [], labels: {}, outputs: []}
      options = default_options.merge(options)

      @labels    = {notice: "info", error: "fehl"}.merge(options[:labels])
      @variables = options[:variables]
      @values    = @variables.map{|var| [var, 0]}.to_h
      @outputs   = options[:outputs]
    end

    # Wert für eine Anzeigevariable direkt setzen.
    # Falls der Wert eine Proc-Instanz ist, wird diese beim Anzeigen aufgerufen.
    def set(name, value)
      @values[name] = value
    end

    # Wert für eine Anzeigevariable lesen.
    # Falls es sich um ein Proc handelt, wird diese ausgeführt.
    def get(name)
      if @values[name].class == Proc
        @values[name].call(self)
      else
        @values[name]
      end
    end

    # Wert für eine Anzeigevariable um Wert amount erhöhen.
    def increase(name, amount=1)
      @values[name] += amount
    end

    # Eine Nachricht loggen.
    # Severity bezeichnet den schweregrad der Nachricht (:notice oder :error)
    def message(msg, severity=:notice)
      self.puts "[#{_label(severity).upcase}][#{Time.now.strftime "%d.%m.%y %H:%M:%S.%L"}] #{msg}"
    end

    # Hilfsmethode um eine "notice" zu loggen.
    def notice(msg)
      self.message(msg, :notice)
    end

    # Hilfsmethode um einen "error" zu loggen.
    def error(msg)
      self.message(msg, :error)
    end

    # Hilfsmethode um einen weiteren Ausgabe-Stream hinzuzufügen.
    def add_output(output)
      @outputs << output
    end

    # Zeigt einen Header für die Werte an.
    def display_header
      self.puts @variables.map{|name| _label(name)}.join("\t")
    end

    # Zeigt die Werte an
    def display_values
      self.puts @variables.map{|name| self.get(name)}.join("\t")
    end

    # Gibt die Anzahl Sekunden zurück die seit dem ersten Aufruf dieser Methode verstrichen sind.
    def elapsed_time
      @started_at = Time.now.to_i if @started_at.nil?
      Time.now.to_i - @started_at
    end

    # Schreibt eine Zeile auf alle Ausgabe-Streams
    def puts(line)
      @outputs.each{|output| output.puts line}
    end

    # Schreibt einen String auf alle Ausgabe-Streams
    def print(str)
      @outputs.each{|output| output.print str}
    end

    # Gibt falls es ein Label für str gibt dieses zurück, ansonsten str.
    def _label(str)
      if @labels.has_key?(str)
        @labels[str]
      else
        str
      end
    end
  end
end
