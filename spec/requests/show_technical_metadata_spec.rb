# frozen_string_literal: true

RSpec.describe 'Show technical metadata' do
  let(:payload) { { sub: 'sdr' } }
  let(:jwt) { JWT.encode(payload, Settings.hmac_secret, 'HS256') }

  before do
    DroFile.create(druid: 'druid:bc123df4568', filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9',
                   bytes: 10, filetype: 'test', mimetype: 'text/test', height: 14, width: 15)
    DroFile.create(druid: 'druid:bc123df4568', filename: '0002.xyz', md5: '2811cb9f08a0504e1035d198d08edda9', bytes: 11)
  end

  describe 'by druid' do
    context 'when results' do
      let(:response_json) do
        [
          { 'druid' => 'druid:bc123df4568', 'filename' => '0001.html', 'filetype' => 'test',
            'mimetype' => 'text/test', 'bytes' => 10, 'height' => 14, 'width' => 15 },
          { 'druid' => 'druid:bc123df4568', 'filename' => '0002.xyz', 'bytes' => 11 }
        ]
      end

      it 'returns the technical metadata' do
        get '/v1/technical-metadata/druid/druid:bc123df4568',
            headers: { 'Authorization' => "Bearer #{jwt}", 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(response_json)
      end
    end

    context 'when no results' do
      it 'returns 404' do
        get '/v1/technical-metadata/druid/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}", 'Accept' => 'application/json' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
