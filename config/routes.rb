# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope 'v1' do
    post '/technical-metadata', to: 'technical_metadata#create'
    get '/technical-metadata/druid/:druid', to: 'technical_metadata#show_by_druid'
    post '/technical-metadata/audit/:druid', to: 'technical_metadata#audit_by_druid' # POST, since params may be > 2 kB
  end

  resources :home, only: [:index]
  resources :stats, only: [:index] do
    collection do
      get 'general'
      get 'processing'
      get 'pronom'
      get 'mimetype'
    end
  end
  root to: 'stats#index'

  mount Sidekiq::Web => '/queues'
end
