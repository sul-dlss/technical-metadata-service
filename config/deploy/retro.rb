# frozen_string_literal: true

# Note that running this as pres user due to read file permissions issues as techmd user.
server 'dor-techmd-worker-prod-b.stanford.edu', user: 'pres', roles: %w[app worker]

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'
set :deploy_to, '/opt/app/pres/dor_techmd'
