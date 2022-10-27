# frozen_string_literal: true

RSpec.describe FileInfoSerializer do
  let(:serializer) { described_class.new }

  let(:file_info) { FileInfo.new(filepath: 'spec/foo.txt', md5: '123', filename: 'foo.txt') }

  let(:hash) do
    { '_aj_serialized' => 'FileInfoSerializer', 'filepath' => 'spec/foo.txt', 'md5' => '123', 'filename' => 'foo.txt' }
  end

  describe '#serialize?' do
    it 'returns true for a FileInfo' do
      expect(described_class.serialize?(file_info)).to be true
    end

    it 'returns false for other' do
      expect(described_class.serialize?('foo')).to be false
    end
  end

  describe '#serialize' do
    it 'serializes' do
      expect(described_class.serialize(file_info)).to eq(hash)
    end
  end

  describe '#deserialize' do
    it 'deserializes' do
      expect(described_class.deserialize(hash)).to eq(file_info)
    end
  end
end
