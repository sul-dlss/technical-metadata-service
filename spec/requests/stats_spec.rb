# frozen_string_literal: true

RSpec.describe '/' do
  before do
    DroFile.create(druid: 'druid:bc123df4568', filename: '0001.html', md5: '1711cb9f08a05Oaa04e1035d198d08edda9',
                   bytes: 10, filetype: 'testtype', mimetype: 'text/test', image_metadata: { height: 14, width: 15 })
  end

  it 'renders the stats index page' do
    get '/'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Technical Metadata Statistics')
    expect(response.body).to include('General Statistics')
    expect(response.body).to include('Processing Statistics')
    expect(response.body).to include('Top formats')
    expect(response.body).to include('By mime type')
    expect(response.body).to include('By Pronom ID')
  end

  it 'renders the general stats page' do
    get '/stats/general'
    expect(response.body).to include('Total Files')
  end

  it 'renders the processing stats page' do
    get '/stats/processing'
    expect(response.body).to include('In last 10 minutes')
  end

  it 'renders the mime type stats page' do
    get '/stats/mimetype'
    expect(response.body).to include('text/test')
  end

  it 'renders the pronom stats page' do
    get '/stats/pronom'
    expect(response.body).to include('testtype')
  end
end
