require 'spec_helper'

describe Common::IndexFile::IndexFile do
  # Test initialization:
  include TempfileHelper
  let_tempfile(:path_inexistent)
  let(:file_inexistent){ Common::IndexFile::IndexFile.new(path_inexistent) }


  # The tests:
  it "doesn't autocreate" do
    expect(File).to_not exist(path_inexistent)
    expect(file_inexistent.exists?).to eq(false)
  end

  it "invokes reload on initialization" do
    expect(file_inexistent).to receive(:reload)
    file_inexistent.send(:initialize, path_inexistent)
  end

  it "loads size of the file on reload" do

  end
end
