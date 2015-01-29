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

  # key: The name of the var to be set
  # local_path: The path of the file within the assets folder
  def let_asset(key, local_path)
    absolute_path = File.join(File.dirname(__FILE__), "..", "assets", local_path)
    let(key){ Asset.new(absolute_path) }
  end
end
