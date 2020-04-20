# frozen_string_literal: true

RSpec.describe 'Request create technical metadata' do
  let(:data) do
    { druid: 'druid:bc123df4567',
      files: [
        'file:///spec/fixtures/test/0001.html',
        'file:///spec/fixtures/test/bar.txt',
        'file:///spec/fixtures/test/foo.txt',
        'file:///spec/fixtures/test/one%20space.txt'
      ],
      force: true }
  end
  let(:payload) { { sub: 'sdr' } }
  let(:jwt) { JWT.encode(payload, Settings.hmac_secret, 'HS256') }
  let(:job) { class_double(TechnicalMetadataJob, perform_later: nil) }

  before do
    allow(TechnicalMetadataWorkflowJob).to receive(:set).and_return(job)
  end

  context 'when authorized' do
    let(:filepaths) do
      ['/spec/fixtures/test/0001.html',
       '/spec/fixtures/test/bar.txt',
       '/spec/fixtures/test/foo.txt',
       '/spec/fixtures/test/one space.txt']
    end

    context 'when lane-id not provided' do
      it 'queues a job to default queue' do
        post '/v1/technical-metadata',
             params: data.to_json,
             headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status(:ok)
        expect(TechnicalMetadataWorkflowJob).to have_received(:set).with(queue: :default)
        expect(job).to have_received(:perform_later).with(druid: 'druid:bc123df4567',
                                                          filepaths: filepaths, force: true)
      end
    end

    context 'when default lane-id provided' do
      it 'queues a job to default queue' do
        post '/v1/technical-metadata',
             params: data.merge('lane-id' => 'default').to_json,
             headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status(:ok)
        expect(TechnicalMetadataWorkflowJob).to have_received(:set).with(queue: :default)
        expect(job).to have_received(:perform_later).with(druid: 'druid:bc123df4567',
                                                          filepaths: filepaths, force: true)
      end
    end

    context 'when low lane-id provided' do
      it 'queues a job to low queue' do
        post '/v1/technical-metadata',
             params: data.merge('lane-id' => 'low').to_json,
             headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status(:ok)
        expect(TechnicalMetadataWorkflowJob).to have_received(:set).with(queue: :low)
        expect(job).to have_received(:perform_later).with(druid: 'druid:bc123df4567',
                                                          filepaths: filepaths, force: true)
      end
    end
  end

  context 'when unauthorized' do
    it 'returns 401' do
      post '/v1/technical-metadata',
           params: data.to_json,
           headers: { 'Content-Type' => 'application/json' }

      expect(response).to be_unauthorized
      expect(job).not_to have_received(:perform_later)
    end
  end
end
