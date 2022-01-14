# frozen_string_literal: true

require 'open3'

RSpec.describe ImageCharacterizerService do
  let(:service) { described_class.new }
  let(:err) { '' }

  before do
    allow(Open3).to receive(:capture3).and_return([output, err, status])
  end

  describe '#version' do
    let(:version) { service.version }

    before do
      allow(Open3).to receive(:capture2e).and_return([output, status])
    end

    context 'when exiftool returns version' do
      let(:output) do
        <<~OUTPUT
          11.85
        OUTPUT
      end
      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns version' do
        expect(version).to eq('11.85')
        expect(Open3).to have_received(:capture2e).with('exiftool -ver')
      end
    end

    context 'when exiftool fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { version }.to raise_error(ImageCharacterizerService::Error)
      end
    end

    context 'when exiftool produces unexpected results' do
      let(:status) { instance_double(Process::Status, success?: true) }
      let(:output) { 'What??' }

      it 'raises' do
        expect { version }.to raise_error(ImageCharacterizerService::Error)
      end
    end
  end

  describe '#characterize' do
    let(:characterization) { service.characterize(filepath: 'bar.png') }

    context 'when file is characterized' do
      let(:output) do
        <<~OUTPUT
          [{
            "SourceFile": "bar.png",
            "ImageHeight": 694,
            "ImageWidth": 1366
          }]
        OUTPUT
      end
      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns height and width' do
        expect(characterization).to eq(height: 694, width: 1366)
        expect(Open3).to have_received(:capture3).with('exiftool', '-ImageHeight', '-ImageWidth', '-json', 'bar.png')
      end
    end

    context 'when file is not characterized' do
      let(:output) do
        <<~OUTPUT
          [{
            "SourceFile": "bar.png"
          }]
        OUTPUT
      end
      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns nil' do
        expect(characterization).to eq(nil)
      end
    end

    context 'when exiftool fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { characterization }.to raise_error(ImageCharacterizerService::Error)
      end
    end

    context 'when exiftool emits warnings' do
      let(:status) { instance_double(Process::Status, success?: true) }
      let(:err) do
        'Deep recursion on subroutine "Image::ExifTool::ProcessDirectory" ' \
          'at /usr/share/perl5/vendor_perl/Image/ExifTool/Exif.pm line 6340'
      end
      let(:output) do
        <<~OUTPUT
          [{
            "SourceFile": "bar.png",
            "ImageHeight": 694,
            "ImageWidth": 1366
          }]
        OUTPUT
      end

      it 'returns height and width' do
        expect(characterization).to eq(height: 694, width: 1366)
        expect(Open3).to have_received(:capture3).with('exiftool', '-ImageHeight', '-ImageWidth', '-json', 'bar.png')
      end
    end

    context 'when exiftool produces unexpected results' do
      let(:status) { instance_double(Process::Status, success?: true) }
      let(:output) do
        <<~OUTPUT
          [{
            "SourceFile": "xbar.png",
            "ImageHeight": 694,
            "ImageWidth": 1366
          }]
        OUTPUT
      end

      it 'raises' do
        expect { characterization }.to raise_error(ImageCharacterizerService::Error)
      end
    end
  end
end
