# frozen_string_literal: true

RSpec.describe TechnicalMetadataJob do
  let(:job) { described_class.new }

  let(:druid) { 'druid:abc123' }

  let(:filepath_map) do
    {
      'spec/fixtures/test/0001.html' => '0001.html',
      'spec/fixtures/test/bar.txt' => 'bar.txt',
      'spec/fixtures/test/foo.txt' => 'foo.txt'
    }
  end

  before do
    allow(TechnicalMetadataGenerator).to receive(:generate).and_return(errors)
    allow(Honeybadger).to receive(:notify)
    job.perform(druid:, filepath_map:, force: true)
  end

  context 'when no errors' do
    let(:errors) { [] }

    it('does nothing') do
      expect(TechnicalMetadataGenerator).to have_received(:generate).with(druid:,
                                                                          filepath_map:,
                                                                          force: true)
    end
  end

  context 'when an error' do
    let(:errors) { ['Ooops'] }

    it('notifies Honeybadger') do
      expect(Honeybadger).to have_received(:notify)
    end
  end
end
