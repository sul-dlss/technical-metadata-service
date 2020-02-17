# frozen_string_literal: true

# Sidekiq configuration (run three processes)
# see sidekiq.yml for concurrency and queue settings
set :sidekiq_env, 'production'
set :sidekiq_processes, 3
