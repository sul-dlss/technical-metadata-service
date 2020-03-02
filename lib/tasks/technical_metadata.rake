# frozen_string_literal: true

namespace :techmd do
  desc 'Generate technical metadata'
  task :generate, %i[druid filepaths] => :environment do |_task, args|
    errors = TechnicalMetadataGenerator.generate(druid: args[:druid], filepaths: args[:filepaths].split(' '))
    if errors.empty?
      puts 'Success'
    else
      puts "Failed: #{errors}"
    end
  end
end
