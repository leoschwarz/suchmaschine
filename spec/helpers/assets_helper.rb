# Ein Mixinmodul welches einem Test ermöglicht den Inhalt einer Datei aus
# dem "assets" Verzeichnis zu lesen.
module AssetsHelper
  class Asset
    def initialize(path)
      @path = path
    end

    def path
      @path
    end

    def content
      @content ||= File.read(@path)
      @content
    end

    def size
      @size ||= File.size(@path)
      @size
    end
  end

  # Wie der let Befehl kann mit einem Aufruf diser Methode eine Variabel
  # für den Test definiert werden, welche eine Asset Instanz initialisiert.
  # @param key [String] Der Name der zu definierenden Variabel
  # @param local_path [String] Der Pfad ausgehend vom assets Verzeichnis zur ge-
  #                            wünschten Datei.
  def let_asset(key, local_path)
    absolute_path = File.join(File.dirname(__FILE__), "..", "assets", local_path)
    let(key){ Asset.new(absolute_path) }
  end
end
