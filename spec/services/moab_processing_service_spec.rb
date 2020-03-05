# frozen_string_literal: true

RSpec.describe MoabProcessingService do
  let(:service) { described_class.new(druid: druid, force: true) }

  let(:druid) { 'druid:bj102hs9687' }

  describe '#process' do
    before do
      allow(TechnicalMetadataJob).to receive(:perform_later)
      service.process
    end

    it 'queues the job' do
      expect(TechnicalMetadataJob).to have_received(:perform_later)
        .with(druid: druid,
              filepaths: ['spec/fixtures/storage_root01/sdr2objects/bj/102/hs/9687/bj102hs9687/v0001/data/content/eric-smith-dissertation.pdf',
                          'spec/fixtures/storage_root01/sdr2objects/bj/102/hs/9687/bj102hs9687/v0001/data/content/eric-smith-dissertation-augmented.pdf'],
              force: true)
    end
  end
end
