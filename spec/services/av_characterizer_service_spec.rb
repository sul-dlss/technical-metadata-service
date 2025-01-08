# frozen_string_literal: true

require 'open3'

RSpec.describe AvCharacterizerService do
  let(:service) { described_class.new }
  let(:status) { instance_double(Process::Status, success?: true) }
  let(:volume_detect) do
    <<~VOLUME
      Lots of stuff here
      [Parsed_volumedetect_0 @ 0x6000012f00b0] n_samples: 28525216
      [Parsed_volumedetect_0 @ 0x6000012f00b0] mean_volume: -24.2 dB
      [Parsed_volumedetect_0 @ 0x6000012f00b0] max_volume: -4.7 dB
      More unused stuff here
    VOLUME
  end
  let(:track_info) { 'track info' }
  let(:ffmpeg_command) { "ffmpeg -i #{filepath} -af 'volumedetect' -vn -sn -dn -f null /dev/null" }
  let(:ffprobe_command) { "ffprobe -i #{filepath} -show_streams -select_streams a -loglevel error" }

  before do
    allow(Open3).to receive(:capture2e).with('mediainfo', '-f', '--Output=JSON', /.*/).and_return([output, status])
    allow(Open3).to receive(:capture2e).with('mediainfo --Version').and_return([output, status])
    allow(Open3).to receive(:capture2e).with(%r{ffmpeg -i .* -af 'volumedetect' -vn -sn -dn -f null /dev/null})
                                       .and_return([volume_detect, status])
    allow(Open3).to receive(:capture2e).with(/ffprobe -i .* -show_streams -select_streams a -loglevel error/)
                                       .and_return([track_info, status])
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
      let(:output) { 'What??' }

      it 'raises' do
        expect { version }.to raise_error(AvCharacterizerService::Error)
      end
    end
  end

  describe '#characterize' do
    let(:filepath) { 'noam.ogg' }
    let(:characterization) { service.characterize(filepath:) }

    context 'when audio file is characterized' do
      let(:output) do
        <<~OUTPUT
          {
          "media": {
          "@ref": "#{filepath}",
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
          "Encoded_Date": #{encoded_date},
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

      context 'when date is UTC' do
        let(:encoded_date) { '"UTC 2020-02-27 18:23:48"' }

        it 'returns av_metadata and track metadata' do
          expect(characterization).to eq([{ audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002,
                                            encoded_date: '2020-02-27T18:23:48+00:00' },
                                          [{ part_type: 'audio', part_id: '28470', order: nil, format: 'Vorbis',
                                             audio_metadata: { channels: '1', sampling_rate: 44_100,
                                                               mean_volume: -24.2, max_volume: -4.7,
                                                               stream_size: 10_020 },
                                             video_metadata: nil, other_metadata: nil }]])
          expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
          expect(Open3).to have_received(:capture2e).with(ffprobe_command)
          expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
        end

        context 'when no audio track is detected by ffprobe' do
          let(:track_info) { '' }

          it 'does not record the volume levels' do
            expect(characterization).to eq([{ audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002,
                                              encoded_date: '2020-02-27T18:23:48+00:00' },
                                            [{ part_type: 'audio', part_id: '28470', order: nil, format: 'Vorbis',
                                               audio_metadata: { channels: '1', sampling_rate: 44_100,
                                                                 stream_size: 10_020 },
                                               video_metadata: nil, other_metadata: nil }]])
            expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
            expect(Open3).to have_received(:capture2e).with(ffprobe_command)
            expect(Open3).not_to have_received(:capture2e).with(ffmpeg_command)
          end
        end

        context 'when a very quiet audio track is detected by ffprobe' do
          let(:volume_detect) do
            <<~VOLUME
              Lots of stuff here
              [Parsed_volumedetect_0 @ 0x6000012f00b0] n_samples: 28525216
              [Parsed_volumedetect_0 @ 0x6000012f00b0] mean_volume: -45.2 dB
              [Parsed_volumedetect_0 @ 0x6000012f00b0] max_volume: -31.7 dB
              More unused stuff here
            VOLUME
          end

          it 'records the volume levels' do
            expect(characterization).to eq([{ audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002,
                                              encoded_date: '2020-02-27T18:23:48+00:00' },
                                            [{ part_type: 'audio', part_id: '28470', order: nil, format: 'Vorbis',
                                               audio_metadata: { channels: '1', sampling_rate: 44_100,
                                                                 mean_volume: -45.2, max_volume: -31.7,
                                                                 stream_size: 10_020 },
                                               video_metadata: nil, other_metadata: nil }]])
            expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
            expect(Open3).to have_received(:capture2e).with(ffprobe_command)
            expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
          end
        end
      end

      context 'when date has a colon in the date part and is UTC' do
        let(:encoded_date) { '"UTC 2020:02:27 18:23:48"' }

        it 'returns av_metadata and track metadata' do
          expect(characterization).to eq([{ audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002,
                                            encoded_date: '2020-02-27T18:23:48+00:00' },
                                          [{ part_type: 'audio', part_id: '28470', order: nil, format: 'Vorbis',
                                             audio_metadata: { channels: '1', sampling_rate: 44_100,
                                                               mean_volume: -24.2, max_volume: -4.7,
                                                               stream_size: 10_020 },
                                             video_metadata: nil, other_metadata: nil }]])
          expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
          expect(Open3).to have_received(:capture2e).with(ffprobe_command)
          expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
        end
      end

      context 'when date does not have a timezone' do
        let(:encoded_date) { '"2020-02-27 18:23:48"' }

        it 'returns av_metadata and track metadata' do
          expect(characterization).to eq([{ audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002,
                                            encoded_date: '2020-02-27T18:23:48+00:00' },
                                          [{ part_type: 'audio', part_id: '28470', order: nil, format: 'Vorbis',
                                             audio_metadata: { channels: '1', sampling_rate: 44_100,
                                                               mean_volume: -24.2, max_volume: -4.7,
                                                               stream_size: 10_020 },
                                             video_metadata: nil, other_metadata: nil }]])
          expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
          expect(Open3).to have_received(:capture2e).with(ffprobe_command)
          expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
        end
      end

      context 'when date has colons in the date part and does not have a timezone' do
        let(:encoded_date) { '"2020:02:27 18:23:48"' }

        it 'returns av_metadata and track metadata' do
          expect(characterization).to eq([{ audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002,
                                            encoded_date: '2020-02-27T18:23:48+00:00' },
                                          [{ part_type: 'audio', part_id: '28470', order: nil, format: 'Vorbis',
                                             audio_metadata: { channels: '1', sampling_rate: 44_100,
                                                               mean_volume: -24.2, max_volume: -4.7,
                                                               stream_size: 10_020 },
                                             video_metadata: nil, other_metadata: nil }]])
          expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
          expect(Open3).to have_received(:capture2e).with(ffprobe_command)
          expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
        end
      end

      context 'when unparseable date' do
        let(:encoded_date) { '"2017.05.10 193630+0000"' }

        it 'returns av_metadata and track metadata' do
          expect(characterization).to eq([{ audio_count: 1, file_extension: 'ogg', format: 'Ogg', duration: 1.002 },
                                          [{ part_type: 'audio', part_id: '28470', order: nil, format: 'Vorbis',
                                             audio_metadata: { channels: '1', sampling_rate: 44_100,
                                                               mean_volume: -24.2, max_volume: -4.7,
                                                               stream_size: 10_020 },
                                             video_metadata: nil, other_metadata: nil }]])
          expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
          expect(Open3).to have_received(:capture2e).with(ffprobe_command)
          expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
        end
      end
    end

    context 'when video file is characterized' do
      let(:filepath) { 'max.webm' }
      let(:characterization) { service.characterize(filepath:) }

      let(:output) do
        <<~OUTPUT
          {
          "media": {
          "@ref": "#{filepath}",
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
                                           audio_metadata: { codec_id: 'A_OPUS', channels: '2',
                                                             mean_volume: -24.2, max_volume: -4.7,
                                                             sampling_rate: 48_000, bit_depth: 32 },
                                           video_metadata: nil, other_metadata: nil }]])
        expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
        expect(Open3).to have_received(:capture2e).with(ffprobe_command)
        expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
      end
    end

    context 'when file with text track is characterized' do
      let(:filepath) { 'make_believe.xyz' }
      let(:characterization) { service.characterize(filepath:) }

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

      it 'returns av_metadata and track metadata' do
        expect(characterization).to eq([{ file_extension: 'xyz', format: 'XYZ' },
                                        [{ part_type: 'text', part_id: '2', order: 1, format: nil,
                                           audio_metadata: nil,
                                           video_metadata: nil, other_metadata: nil }]])
        expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
      end
    end

    context 'when file with other track is characterized' do
      let(:characterization) { service.characterize(filepath:) }

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

      it 'returns av_metadata and track metadata' do
        expect(characterization).to eq([{ file_extension: 'xyz', format: 'XYZ' },
                                        [{ part_type: 'other', part_id: '2', order: 1, format: nil,
                                           audio_metadata: nil,
                                           video_metadata: nil,
                                           other_metadata: { title: } }]])
        expect(Open3).to have_received(:capture2e).with('mediainfo', '-f', '--Output=JSON', filepath)
      end
    end

    context 'when mediainfo fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { characterization }.to raise_error(AvCharacterizerService::Error)
      end
    end
  end

  describe '#audio_track?' do
    let(:filepath) { 'test.mp3' }
    let(:format) { 'MPEG Audio' }

    context 'when file has an audio track' do
      it 'returns true' do
        expect(service.send(:audio_track?, filepath, format)).to be true
      end
    end

    context 'when file has no audio track' do
      let(:track_info) { '' }

      it 'returns false' do
        expect(service.send(:audio_track?, filepath, format)).to be false
      end
    end

    context 'when it is a MIDI file' do
      let(:filepath) { 'test.mid' }
      let(:format) { 'MIDI' }

      it 'returns false' do
        expect(service.send(:audio_track?, filepath, format)).to be false
      end
    end

    context 'when ffprobe fails' do
      let(:track_info) { 'error output' }
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises an error' do
        expect { service.send(:audio_track?, filepath, format) }.to raise_error(AvCharacterizerService::Error)
      end
    end
  end

  describe '#compute_volume_levels' do
    let(:filepath) { 'test.mp3' }

    context 'when ffmpeg returns volume data successfully' do
      let(:volume_detect) do
        <<~VOLUME
          [Parsed_volumedetect_0 @ 0x6000012f00b0] n_samples: 28525216
          [Parsed_volumedetect_0 @ 0x6000012f00b0] mean_volume: -24.2 dB
          [Parsed_volumedetect_0 @ 0x6000012f00b0] max_volume: -4.7 dB
        VOLUME
      end

      it 'returns hash with mean and max volume levels' do
        expect(service.send(:compute_volume_levels, filepath)).to eq(
          mean_volume: -24.2,
          max_volume: -4.7
        )
        expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
      end
    end

    context 'when ffmpeg returns volume data that cannot be parsed' do
      let(:volume_detect) do
        <<~VOLUME
          Nothing but total nonsense returned
        VOLUME
      end

      it 'returns hash with mean and max volume levels set to nil' do
        expect(service.send(:compute_volume_levels, filepath)).to eq(
          mean_volume: nil,
          max_volume: nil
        )
        expect(Open3).to have_received(:capture2e).with(ffmpeg_command)
      end
    end

    context 'when ffmpeg command fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }
      let(:volume_detect) { 'error output' }

      it 'raises an error' do
        expect { service.send(:compute_volume_levels, filepath) }.to raise_error(AvCharacterizerService::Error)
      end
    end
  end
end
