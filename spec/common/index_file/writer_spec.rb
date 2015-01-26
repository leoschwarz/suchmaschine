require 'spec_helper'

describe Common::IndexFile::Writer do
  include TempfileHelper
  let_tempfile(:path)
  let(:writer){ Common::IndexFile::Writer.new(path, 0, 200) }

  def raw_content(p)
    content = File.binread(p)
    content.force_encoding("utf-8")
    content
  end

  def size(p)
    if File.exist? p
      File.size p
    else
      0
    end
  end

  it "file doesn't exist already" do
    expect(File).to_not exist(path)
  end

  it "creates file on first write" do
    writer.write_header("abc",2)
    writer.flush
    expect(File).to exist(path)
  end

  it "flushes automatically if threshold hit" do
    writer = Common::IndexFile::Writer.new(path, 0, 40)
    writer.write_header("abc",0) # -> 24B
    expect(size(path)).to eq(0)
    writer.write_header("xyz",0) # -> 48B
    expect(size(path)).to eq(48)
    writer.write_header("zzz",0) # -> 72B
    expect(size(path)).to eq(48)
    writer.flush()
    expect(size(path)).to eq(72)
  end

  it "writes header" do
    writer.write_header("abc", 4)
    writer.flush
    expect(File.size(path)).to eq(24)
    expect(raw_content path).to eq("abc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04")
  end

  it "writes row" do
    writer.write_row(0.5, "900150983cd24fb0d6963f7d28e17f72")
    writer.flush
    expect(File.size(path)).to eq(20)
    expect(raw_content path).to eq("?\x00\x00\x00\t\x10\x05\x89\xC3-\xF4\vmi\xF3\xD7\x82\x1E\xF7'")
  end

  it "writes rows" do
    rows = []
    rows << [0.4, "900150983cd24fb0d6963f7d28e17f72"]
    rows << [1.8, "26e2fb2a50c40b0b0e1e4c9ce369a834"]
    writer.write_rows(rows)
    writer.flush
    expect(File.size(path)).to eq(40)
    expect(raw_content path).to eq(">\xCC\xCC\xCD\t\u0010\u0005\x89\xC3-\xF4\vmi\xF3ׂ\u001E\xF7'?\xE6ffb.\xBF\xA2\u0005L\xB0\xB0\xE0\xE1\xC4\xC9>\x96\x8AC")
  end
end
