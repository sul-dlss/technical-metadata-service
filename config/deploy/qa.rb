# frozen_string_literal: true

server 'dor-techmd-qa-a.stanford.edu', user: 'techmd', roles: %w[web app db worker]
server 'dor-techmd-worker-qa-a.stanford.edu', user: 'techmd', roles: %w[app worker]

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'
