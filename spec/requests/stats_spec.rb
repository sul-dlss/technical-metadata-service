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
    expect(response.body).to match(/Processing Statistics/)
    expect(response.body).to match(/Top formats/)
    expect(response.body).to match(/By mime type/)
    expect(response.body).to match(/By Pronom ID/)
  end

  it 'renders the general stats page' do
    get '/stats/general'
    expect(response.body).to match(/Total Files/)
  end

  it 'renders the processing stats page' do
    get '/stats/processing'
    expect(response.body).to match(/In last 10 minutes/)
  end

  it 'renders the mime type stats page' do
    get '/stats/mimetype'
    expect(response.body).to match(%r{text/test})
  end

  it 'renders the pronom stats page' do
    get '/stats/pronom'
    expect(response.body).to match(/testtype/)
  end
end
