# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 7.0.1'

gem 'committee' # validates Open API spec (OAS)
gem 'config'
gem 'honeybadger'
gem 'jbuilder'
gem 'jwt'
gem 'okcomputer'
gem 'pg'
gem 'sidekiq', '~> 6.0'
gem 'sidekiq-statistic'
gem 'sprockets-rails'

# Use Puma as the app server
gem 'puma', '~> 5.5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# SDR specific
gem 'dor-workflow-client', '~> 3.17'
gem 'moab-versioning'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', '~> 0.21'
end

group :development do
  gem 'listen', '~> 3.7'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :deployment do
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rvm', require: false # for Ubuntu deployments
  gem 'dlss-capistrano', '~> 3.6', require: false
end

gem 'importmap-rails', '~> 1.0'
