# frozen_string_literal: true

RSpec.describe TechnicalMetadataGenerator do
  let(:service) { described_class.new(druid: druid, filepaths: filepaths) }

  let(:errors) { service.generate }

  let(:druid) { 'druid:abc123' }

  let(:file_identifier_service) { instance_double(FileIdentifierService, version: '1.4.5') }

  before do
    allow(FileIdentifierService).to receive(:new).and_return(file_identifier_service)
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/test/0001.html').and_return('text/html')
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/test/bar.txt').and_return('text/plain')
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/test/foo.txt').and_return('text/plain')
  end

  describe '#generate' do
    context 'when all files exist' do
      let(:filepaths) do
        [
          'spec/fixtures/test/0001.html',
          'spec/fixtures/test/bar.txt',
          'spec/fixtures/test/foo.txt'
        ]
      end

      before do
        # Unchanged
        DroFile.create(druid: druid, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 0,
                       filetype: 'test')
        # MD5 mismatch
        DroFile.create(druid: druid, filename: 'bar.txt', md5: 'xc157a79031e1c40f85931829bc5fc552', bytes: 0,
                       filetype: 'test')
      end

      it 'generates technical metadata for files' do
        expect(errors.length).to eq(0)
        file1 = DroFile.find_by!(druid: druid, filename: '0001.html')
        expect(file1.md5).to eq('1711cb9f08a0504e1035d198d08edda9')
        expect(file1.filetype).to eq('test')

        file2 = DroFile.find_by!(druid: druid, filename: 'bar.txt')
        expect(file2.md5).to eq('c157a79031e1c40f85931829bc5fc552')
        expect(file2.filetype).to eq('text/plain')
        expect(file2.bytes).to eq(4)

        file3 = DroFile.find_by!(druid: druid, filename: 'foo.txt')
        expect(file3.md5).to eq('d3b07384d113edec49eaa6238ad5ff00')
        expect(file3.filetype).to eq('text/plain')
        expect(file3.bytes).to eq(4)
        expect(file3.tool_versions).to eq('siegfried' => '1.4.5')
      end
    end

    context 'when some files do not exist' do
      let(:filepaths) do
        [
          'spec/fixtures/test/0001.html',
          'spec/fixtures/test/bar.txt',
          'spec/fixtures/test/foo.txt',
          'spec/fixtures/test/does_not_exist.txt'
        ]
      end

      it 'returns an error' do
        expect(errors.length).to eq(1)
      end
    end
  end

  context 'when some DroFiles do not exits' do
    let(:filepaths) do
      [
        'spec/fixtures/test/0001.html',
        'spec/fixtures/test/bar.txt',
        'spec/fixtures/test/foo.txt'
      ]
    end

    before do
      DroFile.create(druid: druid, filename: '0002.html', md5: 'e41d8cd98f00b204e9800998ecf8427e', bytes: 0,
                     filetype: 'test')
    end

    it 'deletes them' do
      expect(errors.length).to eq(0)
      expect(DroFile).not_to exist(filename: '0002.html')
    end
  end
end
