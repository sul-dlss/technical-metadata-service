# frozen_string_literal: true

RSpec.describe TechnicalMetadataWorkflowJob do
  let(:job) { described_class.new }

  let(:druid) { 'druid:abc123' }

  let(:file_infos) do
    [
      FileInfo.new(filepath: 'spec/fixtures/test/0001.html', md5: '1711cb9f08a0504e1035d198d08edda9',
                   filename: '0001.html'),
      FileInfo.new(filepath: 'spec/fixtures/test/bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552', filename: 'bar.txt')
    ]
  end

  let(:client) { instance_double(Dor::Workflow::Client, update_status: nil, update_error_status: nil) }

  before do
    allow(TechnicalMetadataGenerator).to receive(:generate_with_file_info).and_return(errors)
    allow(Dor::Workflow::Client).to receive(:new).and_return(client)
    job.perform(druid: druid, file_infos: file_infos)
  end

  context 'when no errors' do
    let(:errors) { [] }

    it('logs success') do
      expect(client).to have_received(:update_status)
    end
  end

  context 'when an error' do
    let(:errors) { ['Ooops'] }

    it('logs error') do
      expect(client).to have_received(:update_error_status)
    end
  end
end
