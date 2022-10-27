# frozen_string_literal: true

RSpec.describe 'Request create technical metadata' do
  let(:data) do
    { druid: 'druid:bc123df4567',
      files: [
        { uri: 'file:///spec/fixtures/test/0001.html', md5: '1711cb9f08a0504e1035d198d08edda9' },
        { uri: 'file:///spec/fixtures/test/bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552' },
        { uri: 'file:///spec/fixtures/test/dir/foo.txt', md5: '4be1a9f251bb9c7dd3343abb94e6e9e1' },
        { uri: 'file:///spec/fixtures/test/one%20space.txt', md5: 'bec8c64f3ade34fe1aa1914c075ba8e9' }
      ],
      basepath: '/spec/fixtures/test',
      force: true }
  end
  let(:payload) { { sub: 'sdr' } }
  let(:jwt) { JWT.encode(payload, Settings.hmac_secret, 'HS256') }
  let(:job) { class_double(TechnicalMetadataJob, perform_later: nil) }

  before do
    allow(TechnicalMetadataWorkflowJob).to receive(:set).and_return(job)
  end

  context 'when authorized' do
    let(:file_infos) do
      [
        FileInfo.new(filepath: '/spec/fixtures/test/0001.html', md5: '1711cb9f08a0504e1035d198d08edda9',
                     filename: '0001.html'),
        FileInfo.new(filepath: '/spec/fixtures/test/bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552',
                     filename: 'bar.txt'),
        FileInfo.new(filepath: '/spec/fixtures/test/dir/foo.txt', md5: '4be1a9f251bb9c7dd3343abb94e6e9e1',
                     filename: 'dir/foo.txt'),
        FileInfo.new(filepath: '/spec/fixtures/test/one space.txt', md5: 'bec8c64f3ade34fe1aa1914c075ba8e9',
                     filename: 'one space.txt')
      ]
    end

    context 'when lane-id not provided' do
      it 'queues a job to default queue' do
        post '/v1/technical-metadata',
             params: data.to_json,
             headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status(:ok)
        expect(TechnicalMetadataWorkflowJob).to have_received(:set).with(queue: :default)
        expect(job).to have_received(:perform_later).with(druid: 'druid:bc123df4567',
                                                          file_infos: file_infos, force: true)
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
                                                          file_infos: file_infos, force: true)
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
                                                          file_infos: file_infos, force: true)
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
