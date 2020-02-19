# frozen_string_literal: true

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

require 'capistrano/bundler'
# These are waiting for dependencies to be used
require 'capistrano/honeybadger'
require 'capistrano/passenger'
# require 'capistrano/rails'
require 'capistrano/rails/migrations'
require 'dlss/capistrano'
require 'capistrano/sidekiq'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
