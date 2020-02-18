# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope 'v1' do
    post '/technical-metadata', to: 'technical_metadata#create'
  end

  mount Sidekiq::Web => '/queues'
end
