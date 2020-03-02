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

  desc 'Generate technical metadata from moab'
  task :generate_moab, %i[druid] => :environment do |_task, args|
    MoabProcessingService.process(druid: args[:druid])
    puts 'Queued'
  end
end
