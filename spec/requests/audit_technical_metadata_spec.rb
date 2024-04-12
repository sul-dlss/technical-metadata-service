# frozen_string_literal: true

RSpec.describe 'Request audit technical metadata' do
  let(:druid) { 'druid:bc123df4567' }

  let(:file_info_0001) { { filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9' } } # rubocop:disable Naming/VariableNumber more consistent with the other var names, and not actually a numbered var anyway
  let(:file_info_bar) { { filename: 'bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552' } }
  let(:file_info_foo) { { filename: 'dir/foo.txt', md5: '4be1a9f251bb9c7dd3343abb94e6e9e1' } }
  let(:file_info_one_space) { { filename: 'one%20space.txt', md5: 'bec8c64f3ade34fe1aa1914c075ba8e9' } }
  let(:file_info_two_spaces) { { filename: 'two%20%20spaces.txt', md5: '2c744dffd279d7e9e0910ce594eb4f4f' } }
  let(:files_param) { [file_info_0001, file_info_bar, file_info_foo, file_info_one_space] }
  let(:data) { { expected_files: files_param } }

  let(:payload) { { sub: 'sdr' } }
  let(:hmac_secret) { Settings.hmac_secret }
  let(:jwt) { JWT.encode(payload, hmac_secret, 'HS256') }
  let(:headers) { { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{jwt}" } }

  context 'when techMD DB has no file info for the druid' do
    it 'returns 404' do
      post("/v1/technical-metadata/audit/#{druid}", params: data.to_json, headers:)

      expect(response).to be_not_found
    end
  end

  context 'when techMD DB has file info for the druid' do
    context 'when techMD DB has info that matches the expected file info' do
      before do
        DroFile.create(druid:, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 11)
        DroFile.create(druid:, filename: 'bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552', bytes: 11)
        DroFile.create(druid:, filename: 'dir/foo.txt', md5: '4be1a9f251bb9c7dd3343abb94e6e9e1', bytes: 11)
        DroFile.create(druid:, filename: 'one space.txt', md5: 'bec8c64f3ade34fe1aa1914c075ba8e9', bytes: 11)
      end

      it 'reports no differences' do
        post("/v1/technical-metadata/audit/#{druid}", params: data.to_json, headers:)

        expect(response).to be_ok
        expect(response.parsed_body).to eq({ 'missing_filenames' => [],
                                             'unexpected_filenames' => [],
                                             'mismatched_checksum_file_infos' => [] })
      end
    end

    context 'when techMD DB is missing file entries contained in the expected file list' do
      let(:files_param) { [file_info_0001, file_info_bar, file_info_foo, file_info_one_space, file_info_two_spaces] }

      before do
        DroFile.create(druid:, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 11)
        DroFile.create(druid:, filename: 'bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552', bytes: 11)
        DroFile.create(druid:, filename: 'one space.txt', md5: 'bec8c64f3ade34fe1aa1914c075ba8e9', bytes: 11)
      end

      it 'reports the missing files' do
        post("/v1/technical-metadata/audit/#{druid}", params: data.to_json, headers:)

        expect(response).to be_ok
        expect(response.parsed_body['missing_filenames']).to contain_exactly('dir/foo.txt', 'two  spaces.txt')
        expect(response.parsed_body['unexpected_filenames']).to eq([])
        expect(response.parsed_body['mismatched_checksum_file_infos']).to eq([])
      end
    end

    context 'when techMD DB has entries for files not contained in the expected file list' do
      let(:files_param) { [file_info_0001, file_info_bar, file_info_foo] }

      before do
        DroFile.create(druid:, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 11)
        DroFile.create(druid:, filename: 'bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552', bytes: 11)
        DroFile.create(druid:, filename: 'dir/foo.txt', md5: '4be1a9f251bb9c7dd3343abb94e6e9e1', bytes: 11)
        DroFile.create(druid:, filename: 'one space.txt', md5: 'bec8c64f3ade34fe1aa1914c075ba8e9', bytes: 11)
        DroFile.create(druid:, filename: 'two  spaces.txt', md5: '2c744dffd279d7e9e0910ce594eb4f4f', bytes: 11)
      end

      it 'reports the unexpected files' do
        post("/v1/technical-metadata/audit/#{druid}", params: data.to_json, headers:)

        expect(response).to be_ok
        expect(response.parsed_body['missing_filenames']).to eq([])
        expect(response.parsed_body['unexpected_filenames']).to contain_exactly('one space.txt', 'two  spaces.txt')
        expect(response.parsed_body['mismatched_checksum_file_infos']).to eq([])
      end
    end

    context 'when techMD DB has the same files as the expected file list, but not all of the hashes match' do
      before do
        DroFile.create(druid:, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 11)
        DroFile.create(druid:, filename: 'bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552', bytes: 11)
        DroFile.create(druid:, filename: 'dir/foo.txt', md5: '4be1a9f251bb9c7dd3343abb94e6e9e1', bytes: 11)
        DroFile.create(druid:, filename: 'one space.txt', md5: '4baac6efc837285acdd8186f162ead4f', bytes: 11)
      end

      it 'reports the files with mismatched checksums' do
        post("/v1/technical-metadata/audit/#{druid}", params: data.to_json, headers:)

        expect(response).to be_ok
        expect(response.parsed_body['missing_filenames']).to eq([])
        expect(response.parsed_body['unexpected_filenames']).to eq([])
        expect(response.parsed_body['mismatched_checksum_file_infos']).to contain_exactly({ 'filename' => 'one space.txt', # rubocop:disable Layout/LineLength
                                                                                            'md5' => '4baac6efc837285acdd8186f162ead4f' }) # rubocop:disable Layout/LineLength
      end
    end

    context 'when techMD DB has the same file info for a different druid' do
      let(:druid) { 'druid:gh123jk4567' }

      before do
        DroFile.create(druid:, filename: '0001.html', md5: '1711cb9f08a0504e1035d198d08edda9', bytes: 11)
        DroFile.create(druid:, filename: 'bar.txt', md5: 'c157a79031e1c40f85931829bc5fc552', bytes: 11)
        DroFile.create(druid:, filename: 'dir/foo.txt', md5: '4be1a9f251bb9c7dd3343abb94e6e9e1', bytes: 11)
        DroFile.create(druid:, filename: 'one space.txt', md5: '4baac6efc837285acdd8186f162ead4f', bytes: 11)
      end

      it 'reports the expected files as missing (since they are for that druid)' do
        post('/v1/technical-metadata/audit/druid:bc123df4567', params: data.to_json, headers:)

        expect(response).to be_not_found
      end
    end
  end

  context 'when unauthorized' do
    let(:hmac_secret) { 'c0mpromised$ecretThatWeAlreadyRotat3d' }

    it 'returns 401' do
      post("/v1/technical-metadata/audit/#{druid}", params: data.to_json, headers:)

      expect(response).to be_unauthorized
    end
  end
end
