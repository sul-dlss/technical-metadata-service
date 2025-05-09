# frozen_string_literal: true

server 'dor-techmd-stage-a.stanford.edu', user: 'techmd', roles: %w[web app db worker]
server 'dor-techmd-worker-stage-a.stanford.edu', user: 'techmd', roles: %w[app worker]

set :rails_env, 'production'
