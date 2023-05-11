# frozen_string_literal: true

RSpec.describe FilepathSupport do
  describe '#filename_for' do
    it 'extracts the filename' do
      expect(described_class.filename_for(filepath: 'spec/fixtures/test/foo.txt',
                                          basepath: 'spec/fixtures/test')).to eq('foo.txt')
      expect(described_class.filename_for(filepath: 'spec/fixtures/test/foo.txt',
                                          basepath: 'spec/fixtures/test/')).to eq('foo.txt')
      expect(described_class.filename_for(filepath: 'spec/fixtures/test/foo.txt',
                                          basepath: 'spec/fixtures')).to eq('test/foo.txt')
    end
  end

  describe '#filepath_map_for' do
    let(:filepaths) do
      [
        'spec/fixtures/test/foo.txt',
        'spec/fixtures/test/dir1/bar.txt'
      ]
    end

    let(:basepath) { 'spec/fixtures/test' }

    it 'returns a hash of filepath to filename' do
      expect(described_class.filepath_map_for(filepaths:, basepath:)).to eq(
        'spec/fixtures/test/foo.txt' => 'foo.txt',
        'spec/fixtures/test/dir1/bar.txt' => 'dir1/bar.txt'
      )
    end
  end
end
# def self.filename_for(filepath:, basepath:)
#   Pathname.new(filepath).relative_path_from(basepath).to_s
# end

# def self.filepath_map_for(filepaths:, basepath:)
#   filepaths.map {|filepath| [filepath, filename_for(filepath: filepath, basepath: basepath)] }.to_h
# end
