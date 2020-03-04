# frozen_string_literal: true

require 'open3'

RSpec.describe AvCharacterizerService do
  let(:service) { described_class.new }

  before do
    allow(Open3).to receive(:capture2e).and_return([output, status])
  end

  describe '#version' do
    let(:version) { service.version }

    context 'when mediainfo returns version' do
      let(:output) do
        <<~OUTPUT
          MediaInfo Command line,
          MediaInfoLib - v19.09
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns version' do
        expect(version).to eq('v19.09')
        expect(Open3).to have_received(:capture2e).with('mediainfo --Version')
      end
    end

    context 'when mediainfo fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { version }.to raise_error(AvCharacterizerService::Error)
      end
    end

    context 'when mediainfo produces unexpected results' do
      let(:status) { instance_double(Process::Status, success?: true) }
      let(:output) { 'What??' }

      it 'raises' do
        expect { version }.to raise_error(AvCharacterizerService::Error)
      end
    end
  end

  describe '#characterize' do
    let(:characterization) { service.characterize(filepath: 'noam.ogg') }

    context 'when audio file is characterized' do
      let(:output) do
        <<~OUTPUT
          {
          "media": {
          "@ref": "noam.ogg",
          "track": [
          {
          "@type": "General",
          "AudioCount": "1",
          "FileExtension": "ogg",
          "Format": "Ogg",
          "FileSize": "10613",
          "Duration": "1.002",
          "OverallBitRate_Mode": "VBR",
          "OverallBitRate": "84735",
          "StreamSize": "593",
          "Encoded_Date": "UTC 2020-02-27 18:23:48",
          "File_Modified_Date": "UTC 2020-02-27 18:23:48",
          "File_Modified_Date_Local": "2020-02-27 10:23:48"
          },
          {
          "@type": "Audio",
          "ID": "28470",
          "Format": "Vorbis",
          "Format_Settings_Floor": "1",
          "Duration": "1.002",
          "BitRate_Mode": "VBR",
          "BitRate": "80000",
          "Channels": "1",
          "SamplingRate": "44100",
          "SamplingCount": "44188",
          "Compression_Mode": "Lossy",
          "StreamSize": "10020",
          "StreamSize_Proportion": "0.94413",
          "Encoded_Library": "Xiph.Org libVorbis I 20020717",
          "Encoded_Library_Name": "libVorbis",
          "Encoded_Library_Version": "1.0",
          "Encoded_Library_Date": "UTC 2002-07-17"
          }
          ]
          }
          }
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns av_metadata and track metadata' do
        expect(characterization).to eq([{ audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002,
                                          encoded_date: '2020-02-27T18:23:48+00:00' },
                                        [{ part_type: 'audio', part_id: '28470', order: nil, format: 'Vorbis',
                                           audio_metadata: { channels: '1', sampling_rate: 44_100,
                                                             stream_size: 10_020 },
                                           video_metadata: nil, other_metadata: nil }]])
        expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', 'noam.ogg')
      end
    end

    context 'when video file is characterized' do
      let(:characterization) { service.characterize(filepath: 'max.webm') }

      let(:output) do
        <<~OUTPUT
          {
          "media": {
          "@ref": "max.webm",
          "track": [
          {
          "@type": "General",
          "VideoCount": "1",
          "AudioCount": "1",
          "FileExtension": "webm",
          "Format": "WebM",
          "Format_Version": "4",
          "FileSize": "10465757",
          "Duration": "33.234",
          "OverallBitRate": "2519289",
          "FrameRate": "29.970",
          "FrameCount": "995",
          "IsStreamable": "Yes",
          "File_Modified_Date": "UTC 2020-02-27 23:35:56",
          "File_Modified_Date_Local": "2020-02-27 15:35:56",
          "Encoded_Application": "Lavf58.20.100",
          "Encoded_Library": "Lavf58.20.100"
          },
          {
          "@type": "Video",
          "StreamOrder": "0",
          "ID": "1",
          "UniqueID": "1",
          "Format": "VP9",
          "CodecID": "V_VP9",
          "Duration": "33.206000000",
          "Width": "640",
          "Height": "480",
          "PixelAspectRatio": "1.000",
          "DisplayAspectRatio": "1.333",
          "FrameRate_Mode": "CFR",
          "FrameRate": "29.970",
          "FrameCount": "995",
          "Encoded_Library": "Lavc58.35.100 libvpx-vp9",
          "Default": "Yes",
          "Forced": "No",
          "Standard": "NTSC"
          },
          {
          "@type": "Audio",
          "StreamOrder": "1",
          "ID": "2",
          "UniqueID": "2",
          "Format": "Opus",
          "CodecID": "A_OPUS",
          "Duration": "33.234000000",
          "Channels": "2",
          "ChannelPositions": "Front: L R",
          "ChannelLayout": "L R",
          "SamplingRate": "48000",
          "SamplingCount": "1595232",
          "BitDepth": "32",
          "Compression_Mode": "Lossy",
          "Delay": "0.000",
          "Delay_Source": "Container",
          "Title": "Stereo",
          "Encoded_Library": "Lavc58.35.100 libopus",
          "Default": "Yes",
          "Forced": "No"
          }
          ]
          }
          }
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns av_metadata and track metadata' do
        expect(characterization).to eq([{ video_count: 1, audio_count: 1, file_extension: 'webm', format: 'WebM',
                                          duration: 33.234, frame_rate: 29.97 },
                                        [{ part_type: 'video', part_id: '1', order: 0, format: 'VP9',
                                           audio_metadata: nil,
                                           video_metadata: { codec_id: 'V_VP9', height: 480, width: 640,
                                                             display_aspect_ratio: 1.333, pixel_aspect_ratio: 1.0,
                                                             frame_rate: 29.97, standard: 'NTSC' },
                                           other_metadata: nil },
                                         { part_type: 'audio', part_id: '2', order: 1, format: 'Opus',
                                           audio_metadata: { codec_id: 'A_OPUS', channels: '2', sampling_rate: 48_000,
                                                             bit_depth: 32 },
                                           video_metadata: nil, other_metadata: nil }]])
        expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', 'max.webm')
      end
    end

    context 'when file with text track is characterized' do
      let(:characterization) { service.characterize(filepath: 'make_believe.xyz') }

      # This output is made up and should be replaced once we have a sample file with a text track.
      let(:output) do
        <<~OUTPUT
          {
          "media": {
          "@ref": "make_believe.xyz",
          "track": [
          {
          "@type": "General",
          "FileExtension": "xyz",
          "Format": "XYZ",
          "FileSize": "10613"
          },
          {
          "@type": "Text",
          "StreamOrder": "1",
          "ID": "2"
          }
          ]
          }
          }
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns av_metadata and track metadata' do
        expect(characterization).to eq([{ file_extension: 'xyz', format: 'XYZ' },
                                        [{ part_type: 'text', part_id: '2', order: 1, format: nil,
                                           audio_metadata: nil,
                                           video_metadata: nil, other_metadata: nil }]])
        expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', 'make_believe.xyz')
      end
    end

    context 'when file with other track is characterized' do
      let(:characterization) { service.characterize(filepath: 'make_believe.xyz') }

      let(:title) { 'Dr. Strangelove or: How I Learned to Stop Worrying and Love the Bomb' }

      # This output is made up and should be replaced once we have a sample file with a text track.
      let(:output) do
        <<~OUTPUT
          {
          "media": {
          "@ref": "make_believe.xyz",
          "track": [
          {
          "@type": "General",
          "FileExtension": "xyz",
          "Format": "XYZ",
          "FileSize": "10613"
          },
          {
          "@type": "Other",
          "StreamOrder": "1",
          "ID": "2",
          "Title": "#{title}"
          }
          ]
          }
          }
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns av_metadata and track metadata' do
        expect(characterization).to eq([{ file_extension: 'xyz', format: 'XYZ' },
                                        [{ part_type: 'other', part_id: '2', order: 1, format: nil,
                                           audio_metadata: nil,
                                           video_metadata: nil,
                                           other_metadata: { title: title } }]])
        expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', 'make_believe.xyz')
      end
    end

    context 'when mediainfo fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { characterization }.to raise_error(AvCharacterizerService::Error)
      end
    end
  end
end
