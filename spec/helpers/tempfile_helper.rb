module TempfileHelper
  def let_tempfile(key)
    # The tempfile is created in it's own variable, so in case it is used, this
    # makes sure it doesn't get deleted to early because of GC.
    tempfile_key = "#{key}_tempfile".to_sym
    let(tempfile_key){ f=Tempfile.new("file"); File.unlink(f); f }
    let(key){ self.send(tempfile_key).path }
  end
end
