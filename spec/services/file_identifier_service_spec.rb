# frozen_string_literal: true

require 'open3'

RSpec.describe FileIdentifierService do
  let(:service) { described_class.new }

  before do
    allow(Open3).to receive(:capture2e).and_return([output, status])
  end

  describe '#version' do
    let(:version) { service.version }

    context 'when siegfried returns version' do
      let(:output) do
        <<~OUTPUT
          siegfried 1.8.0
          /usr/share/siegfried/default.sig (2020-01-21T23:30:42+01:00)
          identifiers:
            - pronom: DROID_SignatureFile_V96.xml; container-signature-20200121.xml
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns version' do
        expect(version).to eq('1.8.0')
        expect(Open3).to have_received(:capture2e).with('sf -version')
      end
    end

    context 'when siegfried fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { version }.to raise_error(FileIdentifierService::Error)
      end
    end

    context 'when siegfried produces unexpected results' do
      let(:status) { instance_double(Process::Status, success?: true) }
      let(:output) { 'What??' }

      it 'raises' do
        expect { version }.to raise_error(FileIdentifierService::Error)
      end
    end
  end

  describe '#identify' do
    let(:identifiers) { service.identify(filepath: '0001.html') }

    context 'when file is identified with old siegfried' do
      let(:output) { '{"siegfried":"1.4.5","scandate":"2020-03-03T12:28:39-05:00","signature":"pronom.sig","created":"2016-02-05T17:41:10+11:00","identifiers":[{"name":"pronom","details":"DROID_SignatureFile_V84.xml; container-signature-20160121.xml"}],"files":[{"filename":"0001.html","filesize": 38,"modified":"2020-02-19T09:11:41-05:00","errors": "","matches": [{"id":"pronom","puid":"fmt/96","format":"Hypertext Markup Language","version":"","mime":"text/html","basis":"extension match; byte match at [[[0 5]] [[31 7]]] (signature 1/2)","warning":""}]}]}' }

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns pronom id and mimetype' do
        expect(identifiers).to eq(['fmt/96', 'text/html'])
        expect(Open3).to have_received(:capture2e).with('sf', '-json', '0001.html')
      end
    end

    # Siegfried returns different formats depending on the version. This tests the other format.
    context 'when file is identified with new siegfried' do
      let(:output) { '{"siegfried":"1.8.0","scandate":"2020-03-03T09:30:57-08:00","signature":"default.sig","created":"2020-01-21T23:30:42+01:00","identifiers":[{"name":"pronom","details":"DROID_SignatureFile_V96.xml; container-signature-20200121.xml"}],"files":[{"filename":"0001.html","filesize": 38,"modified":"2020-03-02T14:45:13-08:00","errors": "","matches": [{"ns":"pronom","id":"fmt/96","format":"Hypertext Markup Language","version":"","mime":"text/html","basis":"extension match html; byte match at [[0 5] [31 7]] (signature 1/2)","warning":""}]}]}' }

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns pronom id and mimetype' do
        expect(identifiers).to eq(['fmt/96', 'text/html'])
        expect(Open3).to have_received(:capture2e).with('sf', '-json', '0001.html')
      end
    end

    context 'when file is not identified' do
      let(:output) { '{"siegfried":"1.8.0","scandate":"2020-02-18T16:44:36-05:00","signature":"default.sig","created":"2020-01-21T23:30:42+01:00","identifiers":[{"name":"pronom","details":"DROID_SignatureFile_V96.xml; container-signature-20200121.xml"}],"files":[{"filename":"0001.html","filesize": 933521532,"modified":"2020-02-18T12:25:17-05:00","errors": "","matches": [{"ns":"pronom","id":"UNKNOWN","format":"","version":"","mime":"","basis":"","warning":"no match"}]}]}' }

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns nil' do
        expect(identifiers).to eq([nil, nil])
      end
    end

    context 'when siegfried fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { identifiers }.to raise_error(FileIdentifierService::Error)
      end
    end

    context 'when siegfried produces unexpected results' do
      let(:status) { instance_double(Process::Status, success?: true) }
      let(:output) { '{"siegfried":"1.8.0","scandate":"2020-02-18T16:44:36-05:00","signature":"default.sig","created":"2020-01-21T23:30:42+01:00","identifiers":[{"name":"pronom","details":"DROID_SignatureFile_V96.xml; container-signature-20200121.xml"}],"files":[{"filename":"xbar.txt","filesize": 4,"modified":"2020-02-18T15:36:15-05:00","errors": "","matches": [{"ns":"pronom","id":"x-fmt/111","format":"Plain Text File","version":"","mime":"text/plain","basis":"extension match txt; text match ASCII","warning":""}]}]}' }

      it 'raises' do
        expect { identifiers }.to raise_error(FileIdentifierService::Error)
      end
    end
  end
end
