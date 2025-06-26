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

  let(:object_client) { instance_double(Dor::Services::Client::Object, workflow: object_workflow) }
  let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow, process:) }
  let(:process) { instance_double(Dor::Services::Client::Process, update: true, update_error: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  context 'when no exception' do
    before do
      allow(TechnicalMetadataGenerator).to receive(:generate_with_file_info).and_return(errors)
      job.perform(druid:, file_infos:)
    end

    context 'when no errors' do
      let(:errors) { [] }

      it('logs success') do
        expect(process).to have_received(:update).with(hash_including(status: 'completed'))
      end
    end

    context 'when an error' do
      let(:errors) { ['Ooops'] }

      it('logs error') do
        expect(process).to have_received(:update_error)
      end
    end
  end

  context 'when an exception occurs' do
    before do
      allow(Honeybadger).to receive(:notify)
      allow(TechnicalMetadataGenerator).to receive(:generate_with_file_info).and_raise(StandardError)
      job.perform(druid:, file_infos:)
    end

    it('logs error and sets workflow step to error') do
      expect(process).to have_received(:update_error)
      expect(Honeybadger).to have_received(:notify)
    end
  end
end
