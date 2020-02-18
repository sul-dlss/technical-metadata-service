# frozen_string_literal: true

RSpec.describe 'Request create technical metadata' do
  before do
    allow(TechnicalMetadataJob).to receive(:perform_later)
  end

  it 'queues a job' do
    post '/v1/technical-metadata',
         params: {
           druid: 'druid:bc123df4567',
           files: [
             'file:///spec/fixtures/test/0001.html',
             'file:///spec/fixtures/test/bar.txt',
             'file:///spec/fixtures/test/foo.txt'
           ]
         }.to_json,
         headers: { 'Content-Type' => 'application/json' }

    filepaths = ['/spec/fixtures/test/0001.html', '/spec/fixtures/test/bar.txt', '/spec/fixtures/test/foo.txt']
    expect(response).to have_http_status(:ok)
    expect(TechnicalMetadataJob).to have_received(:perform_later).with(druid: 'druid:bc123df4567',
                                                                       filepaths: filepaths)
  end
end
