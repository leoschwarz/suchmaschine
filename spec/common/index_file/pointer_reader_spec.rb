require 'spec_helper'

describe Common::IndexFile::PointerReader do
  expected_rows = [
    [:header, "abc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 3],
    [:row, 0.4000000059604645, "0cc175b9c0f1b6a831c399e269772661"],
    [:row, 0.3, "92eb5ffee6ae2fec3ad71c777531578f"],
    [:row, 0.2, "4a8a08f09d37b73795649038408b5f33"],
    [:header, "xyz\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 2],
    [:row, 1.5, "92eb5ffee6ae2fec3ad71c777531578f"],
    [:row, 0.7, "0cc175b9c0f1b6a831c399e269772661"]
  ]
  let_asset(:file, "common/index_file/example.zip")
  let(:reader){ Common::IndexFile::PointerReader.new(file.path, file.size) }

  it "provides current already for the first item" do
    expect(reader.current).to eq(expected_rows[0])
  end

  it "doesn't move pointer after current" do
    reader.current
    expect(reader.current).to eq(expected_rows[0])
  end

  it "moves pointer after shift" do
    reader.shift
    expect(reader.current).to eq(expected_rows[1])
  end

  it "returns current row from shift" do
    expect(reader.shift).to eq(expected_rows[1])
  end

  it "returns void after last row" do
    (expected_rows.size-1).times{ reader.shift }
    expect(reader.shift).to be(nil)
    expect(reader.current).to be(nil)
  end
end
