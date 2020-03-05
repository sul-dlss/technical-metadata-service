# frozen_string_literal: true

RSpec.describe 'Request create technical metadata' do
  let(:data) do
    { druid: 'druid:bc123df4567',
      files: [
        'file:///spec/fixtures/test/0001.html',
        'file:///spec/fixtures/test/bar.txt',
        'file:///spec/fixtures/test/foo.txt'
      ],
      force: true }
  end
  let(:payload) { { sub: 'sdr' } }
  let(:jwt) { JWT.encode(payload, Settings.hmac_secret, 'HS256') }

  before do
    allow(TechnicalMetadataWorkflowJob).to receive(:perform_later)
  end

  context 'when authorized' do
    it 'queues a job' do
      post '/v1/technical-metadata',
           params: data.to_json,
           headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{jwt}" }

      filepaths = ['/spec/fixtures/test/0001.html', '/spec/fixtures/test/bar.txt', '/spec/fixtures/test/foo.txt']
      expect(response).to have_http_status(:ok)
      expect(TechnicalMetadataWorkflowJob).to have_received(:perform_later).with(druid: 'druid:bc123df4567',
                                                                                 filepaths: filepaths, force: true)
    end
  end

  context 'when unauthorized' do
    it 'returns 401' do
      post '/v1/technical-metadata',
           params: data.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to be_unauthorized
      expect(TechnicalMetadataWorkflowJob).not_to have_received(:perform_later)
    end
  end
end
