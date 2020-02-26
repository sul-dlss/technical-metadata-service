# frozen_string_literal: true

RSpec.describe TechnicalMetadataGenerator do
  let(:service) { described_class.new(druid: druid, filepaths: filepaths) }

  let(:errors) { service.generate }

  let(:druid) { 'druid:abc123' }

  let(:file_identifier_service) { instance_double(FileIdentifierService, version: '1.4.5') }

  let(:image_characterizer_service) { instance_double(ImageCharacterizerService, version: '11.85') }

  let(:pdf_characterizer_service) { instance_double(PdfCharacterizerService, version: '0.85.0') }

  before do
    allow(FileIdentifierService).to receive(:new).and_return(file_identifier_service)
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/test/0001.html')
                                                        .and_return(['fmt/96', 'text/html'])
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/test/bar.txt')
                                                        .and_return(['x-fmt/111', 'text/plain'])
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/test/foo.jpg')
                                                        .and_return(['fmt/43', 'image/jpeg'])
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/test/brief.pdf')
                                                        .and_return(['fmt/20', 'application/pdf'])
    allow(ImageCharacterizerService).to receive(:new).and_return(image_characterizer_service)
    allow(image_characterizer_service).to receive(:characterize).with(filepath: 'spec/fixtures/test/foo.jpg')
                                                                .and_return(height: 200, width: 151)
    allow(PdfCharacterizerService).to receive(:new).and_return(pdf_characterizer_service)
    allow(pdf_characterizer_service).to receive(:characterize).with(filepath: 'spec/fixtures/test/brief.pdf').and_return(form: false,
                                                                                                                         pages: 111,
                                                                                                                         tagged: false,
                                                                                                                         encrypted: false,
                                                                                                                         page_size: '612 x 792 pts (letter)',
                                                                                                                         pdf_version: '1.6',
                                                                                                                         text: false)
  end

  describe '#generate' do
    context 'when all files exist' do
      let(:filepaths) do
        [
          'spec/fixtures/test/0001.html',
          'spec/fixtures/test/bar.txt',
          'spec/fixtures/test/foo.jpg',
          'spec/fixtures/test/brief.pdf'
        ]
      end

      before do
        # Unchanged
        DroFile.create(druid: druid, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 0,
                       filetype: 'test', mimetype: 'text/test')
        # MD5 mismatch
        DroFile.create(druid: druid, filename: 'bar.txt', md5: 'xc157a79031e1c40f85931829bc5fc552', bytes: 0,
                       filetype: 'test', mimetype: 'text/test')
      end

      it 'generates technical metadata for files' do
        expect(errors.length).to eq(0)
        file1 = DroFile.find_by!(druid: druid, filename: '0001.html')
        expect(file1.md5).to eq('1711cb9f08a0504e1035d198d08edda9')
        expect(file1.filetype).to eq('test')

        file2 = DroFile.find_by!(druid: druid, filename: 'bar.txt')
        expect(file2.md5).to eq('c157a79031e1c40f85931829bc5fc552')
        expect(file2.filetype).to eq('x-fmt/111')
        expect(file2.mimetype).to eq('text/plain')
        expect(file2.bytes).to eq(4)
        expect(file2.file_create).to be_a_kind_of(Time)
        expect(file2.file_modification).to be_a_kind_of(Time)

        file3 = DroFile.find_by!(druid: druid, filename: 'foo.jpg')
        expect(file3.md5).to eq('5959c720af38282ea0926190e1161ddd')
        expect(file3.filetype).to eq('fmt/43')
        expect(file3.mimetype).to eq('image/jpeg')
        expect(file3.bytes).to eq(16_245)
        expect(file3.image_metadata['height']).to eq(200)
        expect(file3.image_metadata['width']).to eq(151)
        expect(file3.tool_versions).to eq('siegfried' => '1.4.5', 'exiftool' => '11.85')

        file4 = DroFile.find_by!(druid: druid, filename: 'brief.pdf')
        expect(file4.md5).to eq('0e00380c2a5eea678fcb42b39d913463')
        expect(file4.filetype).to eq('fmt/20')
        expect(file4.mimetype).to eq('application/pdf')
        expect(file4.bytes).to eq(624_716)
        expect(file4.pdf_metadata).to eq('form' => false,
                                         'pages' => 111,
                                         'tagged' => false,
                                         'encrypted' => false,
                                         'page_size' => '612 x 792 pts (letter)',
                                         'pdf_version' => '1.6',
                                         'text' => false)
        expect(file4.tool_versions).to eq('siegfried' => '1.4.5', 'poppler' => '0.85.0')
      end
    end

    context 'when some files do not exist' do
      let(:filepaths) do
        [
          'spec/fixtures/test/0001.html',
          'spec/fixtures/test/bar.txt',
          'spec/fixtures/test/foo.jpg',
          'spec/fixtures/test/does_not_exist.txt'
        ]
      end

      it 'returns an error' do
        expect(errors.length).to eq(1)
      end
    end
  end

  context 'when some DroFiles do not exist' do
    let(:filepaths) do
      [
        'spec/fixtures/test/0001.html',
        'spec/fixtures/test/bar.txt',
        'spec/fixtures/test/foo.jpg'
      ]
    end

    before do
      DroFile.create(druid: druid, filename: '0002.html', md5: 'e41d8cd98f00b204e9800998ecf8427e', bytes: 0)
    end

    it 'deletes them' do
      expect(errors.length).to eq(0)
      expect(DroFile).not_to exist(filename: '0002.html')
    end
  end

  context 'when some DroFiles are 0 bytes' do
    let(:filepaths) do
      [
        'spec/fixtures/test/0001.html',
        'spec/fixtures/test/bar.txt',
        'spec/fixtures/test/foo.jpg',
        'spec/fixtures/test/zero.txt'
      ]
    end

    it 'does not identify them' do
      expect(errors.length).to eq(0)
      file = DroFile.find_by!(druid: druid, filename: 'zero.txt')
      expect(file.bytes).to eq(0)
      expect(file.filetype).to be_nil
    end
  end
end
