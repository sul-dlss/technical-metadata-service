# frozen_string_literal: true

RSpec.describe 'Request create technical metadata' do
  let(:data) do
    { druid: 'druid:bc123df4567',
      files: [
        'file:///spec/fixtures/test/0001.html',
        'file:///spec/fixtures/test/bar.txt',
        'file:///spec/fixtures/test/foo.txt'
      ] }
  end

  before do
    allow(TechnicalMetadataJob).to receive(:perform_later)
  end

  context 'when authorized' do
    it 'queues a job' do
      post '/v1/technical-metadata',
           params: data.to_json,
           headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{jwt}" }

      filepaths = ['/spec/fixtures/test/0001.html', '/spec/fixtures/test/bar.txt', '/spec/fixtures/test/foo.txt']
      expect(response).to have_http_status(:ok)
      expect(TechnicalMetadataJob).to have_received(:perform_later).with(druid: 'druid:bc123df4567',
                                                                         filepaths: filepaths)
    end
  end

  context 'when unauthorized' do
    it 'returns 401' do
      post '/v1/technical-metadata',
           params: data.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to be_unauthorized
      expect(TechnicalMetadataJob).not_to have_received(:perform_later)
    end
  end
end
