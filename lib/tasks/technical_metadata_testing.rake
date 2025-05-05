# frozen_string_literal: true

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  desc 'Run rubocop'
  task rubocop: :environment do
    abort 'Please install the rubocop gem to run rubocop.'
  end
end

begin
  require 'rspec/core/rake_task'
rescue LoadError
  desc 'Run RSpec'
  task spec: :environment do
    abort 'Please install the rspec-rails gem to run rspec.'
  end
end

desc 'Run erblint against ERB files'
task erblint: :environment do
  puts 'Running erblint...'
  system('bundle exec erb_lint --lint-all --format compact')
end

desc 'Run all configured linters'
task lint: %i[rubocop erblint]

task(:default).clear

desc 'run linters and tests (for CI)'
task default: %i[lint spec]
