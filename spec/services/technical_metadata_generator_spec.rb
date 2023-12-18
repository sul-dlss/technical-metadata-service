# frozen_string_literal: true

RSpec.describe TechnicalMetadataGenerator do
  let(:service) { described_class.new(druid:, force:) }
  let(:druid) { 'druid:abc123' }
  let(:force) { false }
  let(:filepath_map) { FilepathSupport.filepath_map_for(filepaths:, basepath: 'spec/fixtures/content') }
  let(:file_identifier_service) { instance_double(FileIdentifierService, version: '1.4.5') }
  let(:image_characterizer_service) { instance_double(ImageCharacterizerService, version: '11.85') }
  let(:pdf_characterizer_service) { instance_double(PdfCharacterizerService, version: '0.85.0') }
  let(:av_characterizer_service) { instance_double(AvCharacterizerService, version: 'v19.09') }

  before do
    allow(FileIdentifierService).to receive(:new).and_return(file_identifier_service)
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/content/0001.html')
                                                        .and_return(['fmt/96', 'text/html'])
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/content/bar.txt')
                                                        .and_return(['x-fmt/111', 'text/plain'])
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/content/foo.jpg')
                                                        .and_return(['fmt/43', 'image/jpeg'])
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/content/dir/brief.pdf')
                                                        .and_return(['fmt/20', 'application/pdf'])
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/content/noam.ogg')
                                                        .and_return(['fmt/203', 'audio/ogg'])
    allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/content/max.webm')
                                                        .and_return(['fmt/573', 'video/webm'])

    allow(ImageCharacterizerService).to receive(:new).and_return(image_characterizer_service)
    allow(image_characterizer_service).to receive(:characterize).with(filepath: 'spec/fixtures/content/foo.jpg')
                                                                .and_return(height: 200, width: 151)
    allow(PdfCharacterizerService).to receive(:new).and_return(pdf_characterizer_service)
    allow(pdf_characterizer_service).to receive(:characterize).with(filepath: 'spec/fixtures/content/dir/brief.pdf').and_return(form: false,
                                                                                                                                pages: 111,
                                                                                                                                tagged: false,
                                                                                                                                encrypted: false,
                                                                                                                                page_size: '612 x 792 pts (letter)',
                                                                                                                                pdf_version: '1.6',
                                                                                                                                text: false)
    allow(AvCharacterizerService).to receive(:new).and_return(av_characterizer_service)
    allow(av_characterizer_service).to receive(:characterize).with(filepath: 'spec/fixtures/content/noam.ogg')
                                                             .and_return([
                                                                           { audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002 },
                                                                           [{ part_type: 'audio', part_id: '28470', order: false, format: 'Vorbis', audio_metadata: { channels: '1', sampling_rate: 44_100, stream_size: 10_020 }, video_metadata: nil, other_metadata: nil }]
                                                                         ])
    allow(av_characterizer_service).to receive(:characterize).with(filepath: 'spec/fixtures/content/max.webm').and_return([
                                                                                                                            { video_count: 1, audio_count: 1, file_extension: 'webm', format: 'WebM', duration: 33.234, frame_rate: 29.97 },
                                                                                                                            [{ part_type: 'video', part_id: '1', order: true, format: 'VP9', audio_metadata: nil, video_metadata: { codec_id: 'V_VP9', height: 480, width: 640, display_aspect_ratio: 1.333, pixel_aspect_ratio: 1.0, frame_rate: 29.97 }, other_metadata: nil },
                                                                                                                             { part_type: 'audio', part_id: '2', order: true, format: 'Opus', audio_metadata: { codec_id: 'A_OPUS', channels: '2', sampling_rate: 48_000, bit_depth: 32 }, video_metadata: nil, other_metadata: nil }]
                                                                                                                          ])
  end

  describe '#generate' do
    let(:errors) { service.generate(filepath_map) }

    let(:filepaths) do
      [
        'spec/fixtures/content/0001.html'
      ]
    end

    context 'when a file raises a characterization error' do
      let(:filepath_map) { FilepathSupport.filepath_map_for(filepaths:, basepath: 'spec/fixtures/content') }
      let(:filepaths) { ['spec/fixtures/content/sample.img'] }

      before do
        allow(file_identifier_service).to receive(:identify).with(filepath: 'spec/fixtures/content/sample.img')
                                                            .and_return(['fmt/114', 'image/bmp'])
        allow(image_characterizer_service).to receive(:characterize).with(filepath: 'spec/fixtures/content/sample.img')
                                                                    .and_raise(ImageCharacterizerService::Error, 'Error: Unknown file type')
        allow(Honeybadger).to receive(:notify)
      end

      it 'does not raise an error' do
        expect(errors.length).to eq(0)
        DroFile.find_by!(druid:, filename: 'sample.img')
        expect(Honeybadger).to have_received(:notify).once.with(
          ImageCharacterizerService::Error,
          context: {
            druid:,
            mimetype: 'image/bmp',
            filepath: 'spec/fixtures/content/sample.img',
            filename: 'sample.img',
            tool_versions: nil
          }
        )
      end
    end

    context 'when all files exist' do
      let(:filepaths) do
        [
          'spec/fixtures/content/0001.html',
          'spec/fixtures/content/bar.txt',
          'spec/fixtures/content/foo.jpg',
          'spec/fixtures/content/dir/brief.pdf',
          'spec/fixtures/content/noam.ogg',
          'spec/fixtures/content/max.webm'
        ]
      end

      before do
        # Unchanged
        DroFile.create(druid:, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 0,
                       filetype: 'test', mimetype: 'text/test')
        # MD5 mismatch
        DroFile.create(druid:, filename: 'bar.txt', md5: 'xc157a79031e1c40f85931829bc5fc552', bytes: 0,
                       filetype: 'test', mimetype: 'text/test')
      end

      it 'generates technical metadata for files' do
        expect(errors.length).to eq(0)
        file1 = DroFile.find_by!(druid:, filename: '0001.html')
        expect(file1.md5).to eq('1711cb9f08a0504e1035d198d08edda9')
        expect(file1.filetype).to eq('test')

        file2 = DroFile.find_by!(druid:, filename: 'bar.txt')
        expect(file2.md5).to eq('c157a79031e1c40f85931829bc5fc552')
        expect(file2.filetype).to eq('x-fmt/111')
        expect(file2.mimetype).to eq('text/plain')
        expect(file2.bytes).to eq(4)
        expect(file2.file_modification).to be_a(Time)

        file3 = DroFile.find_by!(druid:, filename: 'foo.jpg')
        expect(file3.md5).to eq('5959c720af38282ea0926190e1161ddd')
        expect(file3.filetype).to eq('fmt/43')
        expect(file3.mimetype).to eq('image/jpeg')
        expect(file3.bytes).to eq(16_245)
        expect(file3.image_metadata['height']).to eq(200)
        expect(file3.image_metadata['width']).to eq(151)
        expect(file3.tool_versions).to eq('siegfried' => '1.4.5', 'exiftool' => '11.85')

        file4 = DroFile.find_by!(druid:, filename: 'dir/brief.pdf')
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

        file5 = DroFile.find_by!(druid:, filename: 'noam.ogg')
        expect(file5.md5).to eq('6343e57b10320404a1cc9eeb36db5121')
        expect(file5.filetype).to eq('fmt/203')
        expect(file5.mimetype).to eq('audio/ogg')
        expect(file5.bytes).to eq(10_613)
        expect(file5.av_metadata).to eq('format' => 'Ogg', 'duration' => 1.002, 'audio_count' => 1, 'file_extension' => 'ogg')
        expect(file5.tool_versions).to eq('mediainfo' => 'v19.09', 'siegfried' => '1.4.5')
        expect(file5.dro_file_parts.size).to eq(1)
        file5_part = file5.dro_file_parts.first
        expect(file5_part.part_id).to eq('28470')
        expect(file5_part.part_type).to eq('audio')
        expect(file5_part.audio_metadata).to eq('channels' => '1', 'stream_size' => 10_020, 'sampling_rate' => 44_100)

        file6 = DroFile.find_by!(druid:, filename: 'max.webm')
        expect(file6.md5).to eq('075af8346dae86aa93feb3666803396d')
        expect(file6.filetype).to eq('fmt/573')
        expect(file6.mimetype).to eq('video/webm')
        expect(file6.bytes).to eq(10_465_757)
        expect(file6.av_metadata).to eq('format' => 'WebM', 'duration' => 33.234, 'frame_rate' => 29.97, 'audio_count' => 1, 'video_count' => 1, 'file_extension' => 'webm')
        expect(file6.tool_versions).to eq('mediainfo' => 'v19.09', 'siegfried' => '1.4.5')
        expect(file6.dro_file_parts.size).to eq(2)
        file6_part = file6.dro_file_parts.first
        expect(file6_part.part_id).to eq('1')
        expect(file6_part.part_type).to eq('video')
        expect(file6_part.video_metadata).to eq('width' => 640, 'height' => 480, 'codec_id' => 'V_VP9', 'frame_rate' => 29.97, 'pixel_aspect_ratio' => 1.0, 'display_aspect_ratio' => 1.333)
      end
    end

    context 'when some files do not exist' do
      let(:filepaths) do
        [
          'spec/fixtures/content/0001.html',
          'spec/fixtures/content/bar.txt',
          'spec/fixtures/content/foo.jpg',
          'spec/fixtures/content/does_not_exist.txt'
        ]
      end

      it 'returns an error' do
        expect(errors.length).to eq(1)
      end
    end

    context 'when some DroFiles do not exist' do
      let(:filepaths) do
        [
          'spec/fixtures/content/0001.html',
          'spec/fixtures/content/bar.txt',
          'spec/fixtures/content/foo.jpg'
        ]
      end

      before do
        DroFile.create(druid:, filename: '0002.html', md5: 'e41d8cd98f00b204e9800998ecf8427e', bytes: 0)
      end

      it 'deletes them' do
        expect(errors.length).to eq(0)
        expect(DroFile).not_to exist(filename: '0002.html')
      end
    end

    context 'when some DroFiles are 0 bytes' do
      let(:filepaths) do
        [
          'spec/fixtures/content/0001.html',
          'spec/fixtures/content/bar.txt',
          'spec/fixtures/content/foo.jpg',
          'spec/fixtures/content/zero.txt'
        ]
      end

      it 'does not identify them' do
        expect(errors.length).to eq(0)
        file = DroFile.find_by!(druid:, filename: 'zero.txt')
        expect(file.bytes).to eq(0)
        expect(file.filetype).to be_nil
      end
    end

    context 'when metadata includes a null character' do
      let(:filepaths) do
        [
          'spec/fixtures/content/dir/brief.pdf'
        ]
      end

      before do
        allow(pdf_characterizer_service).to receive(:characterize).with(filepath: 'spec/fixtures/content/dir/brief.pdf').and_return(form: false,
                                                                                                                                    pages: 111,
                                                                                                                                    tagged: false,
                                                                                                                                    encrypted: false,
                                                                                                                                    page_size: '612 x 792 pts (letter)',
                                                                                                                                    pdf_version: '1.6',
                                                                                                                                    text: false,
                                                                                                                                    creator: "Null character\u0000")
      end

      it 'removes the null character' do
        expect(errors.length).to eq(0)
        file = DroFile.find_by!(druid:, filename: 'dir/brief.pdf')
        expect(file.pdf_metadata).to eq('form' => false,
                                        'pages' => 111,
                                        'tagged' => false,
                                        'encrypted' => false,
                                        'page_size' => '612 x 792 pts (letter)',
                                        'pdf_version' => '1.6',
                                        'text' => false,
                                        'creator' => 'Null character')
      end
    end

    context 'when forcing' do
      let(:filepaths) do
        [
          'spec/fixtures/content/0001.html',
          'spec/fixtures/content/bar.txt'
        ]
      end

      let(:force) { true }

      before do
        # Unchanged
        DroFile.create(druid:, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 0,
                       filetype: 'test', mimetype: 'text/test')
        # MD5 mismatch
        DroFile.create(druid:, filename: 'bar.txt', md5: 'xc157a79031e1c40f85931829bc5fc552', bytes: 0,
                       filetype: 'test', mimetype: 'text/test')
      end

      it 'generates technical metadata for files' do
        expect(errors.length).to eq(0)
        file1 = DroFile.find_by!(druid:, filename: '0001.html')
        expect(file1.md5).to eq('1711cb9f08a0504e1035d198d08edda9')
        expect(file1.filetype).to eq('fmt/96')
        expect(file1.mimetype).to eq('text/html')

        file2 = DroFile.find_by!(druid:, filename: 'bar.txt')
        expect(file2.md5).to eq('c157a79031e1c40f85931829bc5fc552')
        expect(file2.filetype).to eq('x-fmt/111')
        expect(file2.mimetype).to eq('text/plain')
      end
    end
  end

  describe '#generate_with_file_info' do
    let(:errors) { service.generate_with_file_info(file_infos) }

    let(:file_infos) do
      [
        FileInfo.new(filepath: 'spec/fixtures/content/0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', filename: '0001.html')
      ]
    end

    # When no existing DroFile and file exists
    # When no existing DroFile and file does not exist
    # Deletes DroFiles that do not exist

    context 'when there is an existing DroFile with MD5 match' do
      let!(:dro_file) do
        DroFile.create(druid:, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 0,
                       filetype: 'test', mimetype: 'text/test')
      end

      it 'does not generate technical metadata for files' do
        expect(errors.length).to eq(0)
        expect(dro_file.reload.md5).to eq('1711cb9f08a0504e1035d198d08edda9')
        expect(file_identifier_service).not_to have_received(:identify)
      end
    end

    context 'when there is an existing DroFile with MD5 mismatch' do
      let!(:dro_file) do
        DroFile.create(druid:, filename: '0001.html', md5: 'x1711cb9f08a0504e1035d198d08edda9', bytes: 0,
                       filetype: 'test', mimetype: 'text/test')
      end

      it 'generates technical metadata for files' do
        expect(errors.length).to eq(0)
        expect(dro_file.reload.md5).to eq('1711cb9f08a0504e1035d198d08edda9')
        expect(file_identifier_service).to have_received(:identify)
      end
    end

    context 'when there is not an existing DroFile and file exists' do
      it 'does not generate technical metadata for files' do
        expect(errors.length).to eq(0)
        dro_file = DroFile.find_by!(druid:, filename: '0001.html')
        expect(dro_file.md5).to eq('1711cb9f08a0504e1035d198d08edda9')
        expect(file_identifier_service).to have_received(:identify)
      end
    end

    context 'when there is not an existing DroFile and files do not exist' do
      let(:file_infos) do
        [
          FileInfo.new(filepath: 'spec/fixtures/content/does_not_exist.html', md5: '1711cb9f08a0504e1035d198d08edda9', filename: 'does_not_exist.html')
        ]
      end

      it 'returns an error' do
        expect(errors.length).to eq(1)
      end
    end

    context 'when some DroFiles do not exist' do
      before do
        DroFile.create(druid:, filename: '0002.html', md5: 'e41d8cd98f00b204e9800998ecf8427e', bytes: 0)
      end

      it 'deletes them' do
        expect(errors.length).to eq(0)
        expect(DroFile).not_to exist(filename: '0002.html')
      end
    end
  end

  describe 'image?' do
    it 'identifies image mimetypes' do
      expect(service.send(:image?, 'image/png')).to be_truthy
      expect(service.send(:image?, 'foo/bar')).to be_falsey
    end
  end

  describe 'pdf?' do
    it 'identifies pdf mimetypes' do
      expect(service.send(:pdf?, 'application/pdf')).to be_truthy
      expect(service.send(:pdf?, 'foo/bar')).to be_falsey
    end
  end

  describe 'av?' do
    it 'identifies av mimetypes' do
      expect(service.send(:av?, 'application/mp4')).to be_truthy
      expect(service.send(:av?, 'audio/mp4')).to be_truthy
      expect(service.send(:av?, 'video/quicktime')).to be_truthy
      expect(service.send(:av?, 'foo/bar')).to be_falsey
    end
  end

  describe 'zero tracks for an av file' do
    before do
      DroFile.create(druid:, filename: 'not_audio.tar', md5: 'asdfas9000lkjds;alfj34jk', bytes: 0,
                     filetype: 'test', mimetype: 'audio/mp4')
      service.instance_variable_set(:@dro_file_part_inserts, 'not_audio.tar': [])
    end

    it 'insert_dro_file_parts return nil when file has zero tracks' do
      file1 = DroFile.find_by!(druid:, filename: 'not_audio.tar')
      expect(service.send(:insert_dro_file_parts, file1)).to be_nil
    end
  end
end
