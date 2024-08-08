# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'bootsnap', '>= 1.4.2', require: false # # Reduces boot times through caching; required in config/boot.rb
gem 'committee' # validates Open API spec (OAS)
gem 'config'
gem 'honeybadger'
gem 'importmap-rails', '~> 1.0'
gem 'jbuilder' # Build JSON APIs with ease.
gem 'jwt'
gem 'okcomputer'
gem 'pg'
gem 'propshaft'
gem 'puma', '~> 5.6' # app server
gem 'rails', '~> 7.0.1'
gem 'redis', '~>4.8' # for OKComputer check
gem 'sidekiq', '~> 7.0'
gem 'turbo-rails', '~> 1.5.0' # Pin turbo-rails to 1.5.0 until we can upgrade to 2.0.0

# DLSS specific
gem 'dor-workflow-client', '~> 7.0'
gem 'moab-versioning', '~> 6.0'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'erb_lint', require: false
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'simplecov', '~> 0.21'
end

group :development do
  gem 'listen', '~> 3.7'
  gem 'spring' # speeds up rails development by keeping your application running in the background.
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :deployment do
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', require: false
  gem 'dlss-capistrano', require: false
end
