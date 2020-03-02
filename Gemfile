# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.2', '>= 6.0.2.1'

gem 'committee' # validates Open API spec (OAS)
gem 'config'
gem 'honeybadger'
gem 'jbuilder'
gem 'jwt'
gem 'okcomputer'
gem 'pg'
gem 'sidekiq', '~> 5.2'
gem 'sidekiq-statistic'

# Use Puma as the app server
gem 'puma', '~> 4.1'
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
  gem 'rspec-rails', '4.0.0.beta4'
  gem 'rspec_junit_formatter'
  gem 'rubocop', '~> 0.79.0', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', '~> 0.17.1' # 0.18 breaks reporting https://github.com/codeclimate/test-reporter/issues/418
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :deployment do
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-sidekiq', require: false
  gem 'dlss-capistrano', require: false
end
