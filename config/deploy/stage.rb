# frozen_string_literal: true

server 'dor-techmd-stage.stanford.edu', user: 'techmd', roles: %w[web app db]

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'
set :bundle_without, %w[deployment test development].join(' ')
