# frozen_string_literal: true

RSpec.describe '/' do
  before do
    DroFile.create(druid: 'druid:bc123df4568', filename: '0001.html', md5: '1711cb9f08a05Oaa04e1035d198d08edda9',
                   bytes: 10, filetype: 'testtype', mimetype: 'text/test', image_metadata: { height: 14, width: 15 })
  end

  it 'renders the stats index page' do
    get '/'
    expect(response).to have_http_status(:ok)
    expect(response.body).to match(/Technical Metadata Statistics/)
    expect(response.body).to match(/General Statistics/)
    expect(response.body).to match(/Total Files/)
    expect(response.body).to match(/Processing Statistics/)
    expect(response.body).to match(/In last 10 minutes/)
    expect(response.body).to match(/Top formats/)
    expect(response.body).to match(/By mime type/)
    expect(response.body).to match(%r{text/test})
    expect(response.body).to match(/By Pronom ID/)
    expect(response.body).to match(/testtype/)
  end
end
