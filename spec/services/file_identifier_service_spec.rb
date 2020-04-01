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
    let(:identifiers) { service.identify(filepath: 'bar.txt') }

    context 'when file is identified' do
      let(:output) { '{"siegfried":"1.8.0","scandate":"2020-02-18T16:44:36-05:00","signature":"default.sig","created":"2020-01-21T23:30:42+01:00","identifiers":[{"name":"pronom","details":"DROID_SignatureFile_V96.xml; container-signature-20200121.xml"}],"files":[{"filename":"bar.txt","filesize": 4,"modified":"2020-02-18T15:36:15-05:00","errors": "","matches": [{"ns":"pronom","id":"x-fmt/111","format":"Plain Text File","version":"","mime":"text/plain","basis":"extension match txt; text match ASCII","warning":""}]}]}' }

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns pronom id and mimetype' do
        expect(identifiers).to eq(['x-fmt/111', 'text/plain'])
        expect(Open3).to have_received(:capture2e).with('sf', '-json', 'bar.txt')
      end
    end

    context 'when file is not identified' do
      let(:output) { '{"siegfried":"1.8.0","scandate":"2020-02-18T16:44:36-05:00","signature":"default.sig","created":"2020-01-21T23:30:42+01:00","identifiers":[{"name":"pronom","details":"DROID_SignatureFile_V96.xml; container-signature-20200121.xml"}],"files":[{"filename":"bar.txt","filesize": 933521532,"modified":"2020-02-18T12:25:17-05:00","errors": "","matches": [{"ns":"pronom","id":"UNKNOWN","format":"","version":"","mime":"","basis":"","warning":"no match"}]}]}' }

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

    context 'when siegfried reports an error' do
      let(:identifiers) { service.identify(filepath: 'bar.zip') }

      let(:output) do
        <<~OUTPUT
          [ERROR] zip: not a valid zip file
          {"siegfried":"1.8.0","scandate":"2020-04-01T07:04:16-07:00","signature":"default.sig","created":"2020-01-21T23:30:42+01:00","identifiers":[{"name":"pronom","details":"DROID_SignatureFile_V96.xml; container-signature-20200121.xml"}],"files":[{"filename":"bar.zip","filesize": 8372334239,"modified":"2020-03-30T22:43:14-07:00","errors": "zip: not a valid zip file","matches": [{"ns":"pronom","id":"x-fmt/263","format":"ZIP Format","version":"","mime":"application/zip","basis":"extension match zip; byte match at [[0 4] [8372334131 3] [8372334217 4]]","warning":""}]}]}
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns pronom id and mimetype' do
        expect(identifiers).to eq(['x-fmt/263', 'application/zip'])
      end
    end
  end
end
