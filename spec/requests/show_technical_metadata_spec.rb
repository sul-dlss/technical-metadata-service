# frozen_string_literal: true

RSpec.describe 'Show technical metadata' do
  let(:payload) { { sub: 'sdr' } }
  let(:jwt) { JWT.encode(payload, Settings.hmac_secret, 'HS256') }

  before do
    DroFile.create(druid: 'druid:bc123df4568', filename: '0001.html', md5: '1711cb9f08a05Oaa04e1035d198d08edda9',
                   bytes: 10, filetype: 'test', mimetype: 'text/test', image_metadata: { height: 14, width: 15 })
    file = DroFile.create(druid: 'druid:bc123df4568', filename: '0002.xyz', md5: '2811cb9f08a0504e1035d198d08edda9',
                          bytes: 11)
    DroFilePart.create(dro_file: file, part_type: 'audio', order: 1,
                       audio_metadata: { channels: '1', sampling_rate: 44_100,
                                         stream_size: 10_020 })
  end

  describe 'by druid' do
    context 'when results' do
      let(:response_json) do
        [
          { 'druid' => 'druid:bc123df4568', 'filename' => '0001.html', 'filetype' => 'test',
            'mimetype' => 'text/test', 'bytes' => 10, 'image_metadata' => { 'height' => 14, 'width' => 15 } },
          { 'druid' => 'druid:bc123df4568', 'filename' => '0002.xyz', 'bytes' => 11, 'dro_file_parts' => [{
            'part_type' => 'audio',
            'order' => 1,
            'audio_metadata' => {
              'channels' => '1',
              'stream_size' => 10_020,
              'sampling_rate' => 44_100
            }
          }] }
        ]
      end

      it 'returns the technical metadata' do
        get '/v1/technical-metadata/druid/druid:bc123df4568',
            headers: { 'Authorization' => "Bearer #{jwt}", 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(response_json)
      end
    end

    context 'when no results' do
      it 'returns 404' do
        get '/v1/technical-metadata/druid/druid:bc123df4566',
            headers: { 'Authorization' => "Bearer #{jwt}", 'Accept' => 'application/json' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'by druid and filename' do
    let(:headers) { { 'Authorization' => "Bearer #{jwt}", 'Accept' => 'application/json' } }

    context 'when result' do
      let(:response_json) do
        { 'druid' => 'druid:bc123df4568', 'filename' => '0002.xyz', 'bytes' => 11, 'dro_file_parts' => [{
          'part_type' => 'audio',
          'order' => 1,
          'audio_metadata' => {
            'channels' => '1',
            'stream_size' => 10_020,
            'sampling_rate' => 44_100
          }
        }] }
      end

      it 'returns the technical metadata' do
        get "/v1/technical-metadata/druid/druid:bc123df4568/file?#{URI.encode_www_form(filename: '0002.xyz')}",
            headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(response_json)
      end
    end

    context 'when filename has special characters' do
      let(:filenames) do
        ['dir/sub dir/page 1.tif', 'a+b.txt', '100%.txt', '100%25.txt', 'what?.txt', 'number#1.txt',
         'this&that=other.txt', 'ünïcødé 文件.jpg', 'file.json', '.hidden']
      end

      before do
        filenames.each_with_index do |filename, index|
          DroFile.create!(druid: 'druid:bc123df4568', filename:, md5: "md5#{index}", bytes: index)
        end
      end

      it 'returns the technical metadata when encoded with URI.encode_www_form' do
        filenames.each do |filename|
          get "/v1/technical-metadata/druid/druid:bc123df4568/file?#{URI.encode_www_form(filename:)}",
              headers: headers

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body['filename']).to eq(filename)
        end
      end

      it 'returns the technical metadata when encoded with ERB::Util.url_encode' do
        filenames.each do |filename|
          get "/v1/technical-metadata/druid/druid:bc123df4568/file?filename=#{ERB::Util.url_encode(filename)}",
              headers: headers

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body['filename']).to eq(filename)
        end
      end
    end

    context 'when no such file' do
      it 'returns 404' do
        get '/v1/technical-metadata/druid/druid:bc123df4568/file?filename=0003.xyz', headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when no such druid' do
      it 'returns 404' do
        get '/v1/technical-metadata/druid/druid:bc123df4566/file?filename=0001.html', headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when filename is missing' do
      it 'returns 400' do
        get '/v1/technical-metadata/druid/druid:bc123df4568/file', headers: headers

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when filename is empty' do
      it 'returns 400' do
        get '/v1/technical-metadata/druid/druid:bc123df4568/file?filename=', headers: headers

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when filename is blank' do
      it 'returns 404' do
        get '/v1/technical-metadata/druid/druid:bc123df4568/file?filename=%20%20', headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when no Accept header' do
      it 'returns the technical metadata as JSON' do
        get '/v1/technical-metadata/druid/druid:bc123df4568/file?filename=0001.html',
            headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['filename']).to eq('0001.html')
      end
    end
  end
end
