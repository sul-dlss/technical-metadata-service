# frozen_string_literal: true

set :application, 'technical-metadata-service'
set :repo_url, 'https://github.com/sul-dlss/technical-metadata-service.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/opt/app/techmd/dor_techmd'

# Since we use webpack rather than sprockets, change the prefix
# see: http://blog.tap349.com/webpack/2018/05/22/webpack-troubleshooting/
set :assets_prefix, 'packs'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w[config/database.yml config/secrets.yml config/honeybadger.yml]

# Default value for linked_dirs is []
set :linked_dirs, %w[log config/settings vendor/bundle public/system tmp/pids]

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, fetch(:stage)

# update shared_configs before restarting app
before 'deploy:restart', 'shared_configs:update'

# Sidekiq configuration (run three processes)
# see sidekiq.yml for concurrency and queue settings
set :sidekiq_env, 'production'
set :sidekiq_processes, 3
