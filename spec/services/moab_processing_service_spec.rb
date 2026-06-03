# frozen_string_literal: true

RSpec.describe MoabProcessingService do
  let(:service) { described_class.new(druid:, force: true) }

  let(:job) { class_double(TechnicalMetadataJob, perform_later: nil) }

  before do
    allow(TechnicalMetadataJob).to receive(:perform_later)
    allow(Honeybadger).to receive(:notify)
    allow(TechnicalMetadataJob).to receive(:set).and_return(job)
  end

  context 'when item exists and has content' do
    let(:druid) { 'druid:bj102hs9687' }

    it 'queues the job' do
      service.process
      expect(TechnicalMetadataJob).to have_received(:set).with(queue: :retro)
      expect(job).to have_received(:perform_later)
        .with(druid:,
              filepath_map: { 'spec/fixtures/storage_root01/sdr2objects/bj/102/hs/9687/bj102hs9687/v0001/data/content/eric-smith-dissertation.pdf' => 'eric-smith-dissertation.pdf',
                              'spec/fixtures/storage_root01/sdr2objects/bj/102/hs/9687/bj102hs9687/v0001/data/content/dir1/eric-smith-dissertation-augmented.pdf' => 'dir1/eric-smith-dissertation-augmented.pdf' },
              force: true)
    end
  end

  context 'when item does not exist' do
    let(:druid) { 'druid:cj102hs9687' }

    it 'does not queues the job' do
      service.process
      expect(TechnicalMetadataJob).not_to have_received(:set)
      expect(Honeybadger).to have_received(:notify)
    end
  end

  context 'when item has no content' do
    let(:druid) { 'druid:zp131wb3519' }

    it 'does not queues the job' do
      service.process
      expect(TechnicalMetadataJob).not_to have_received(:set)
      expect(Honeybadger).not_to have_received(:notify)
    end
  end

  context 'when item exists' do
    before do
      FileUtils.rm_rf('spec/fixtures/storage_root01/sdr2objects/bj/102/hs/9688/bj102hs9688/v0003/data/content')
    end

    after do
      FileUtils.rm_rf('spec/fixtures/storage_root01/sdr2objects/bj/102/hs/9688/bj102hs9688/v0003/data/content')
    end

    context 'when the missing content is on preservation' do
      let(:druid) { 'druid:bj102hs9688' }

      it 'queues the job' do
        service.process
        expect(TechnicalMetadataJob).to have_received(:set).with(queue: :retro)
        expect(job).to have_received(:perform_later)
          .with(druid:,
                filepath_map: { 'spec/fixtures/storage_root01/sdr2objects/bj/102/hs/9688/bj102hs9688/v0003/data/content/eric-smith-dissertation.pdf' => 'eric-smith-dissertation.pdf',
                                'spec/fixtures/storage_root01/sdr2objects/bj/102/hs/9688/bj102hs9688/v0003/data/content/dir1/eric-smith-dissertation-augmented.pdf' => 'dir1/eric-smith-dissertation-augmented.pdf' },
                force: true)
      end
    end

    context 'when the missing content is not on preservation' do
      let(:druid) { 'druid:bj102hs9689' }

      it 'raises a Moab::FileNotFoundException error' do
        expect { service.process }.to raise_error(Moab::FileNotFoundException)
        expect(TechnicalMetadataJob).not_to have_received(:set)
      end
    end
  end
end
