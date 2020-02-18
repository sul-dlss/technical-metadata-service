# frozen_string_literal: true

RSpec.describe TechnicalMetadataJob do
  let(:job) { described_class.new }

  let(:druid) { 'druid:abc123' }

  let(:filepaths) do
    [
      'spec/fixtures/test/0001.html',
      'spec/fixtures/test/bar.txt',
      'spec/fixtures/test/foo.txt'
    ]
  end

  let(:client) { instance_double(Dor::Workflow::Client, update_status: nil, update_error_status: nil) }

  before do
    allow(TechnicalMetadataGenerator).to receive(:generate).and_return(errors)
    allow(Dor::Workflow::Client).to receive(:new).and_return(client)
    job.perform(druid: druid, filepaths: filepaths)
  end

  context 'when no errors' do
    let(:errors) { [] }

    it('logs success') do
      expect(client).to have_received(:update_status)
    end
  end

  context 'when no errors' do
    let(:errors) { ['Ooops'] }

    it('logs success') do
      expect(client).to have_received(:update_error_status)
    end
  end
end
