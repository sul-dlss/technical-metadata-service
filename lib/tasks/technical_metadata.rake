# frozen_string_literal: true

namespace :techmd do
  desc 'Generate technical metadata (synchronously) from druid + filepaths'
  task :generate, %i[druid filepaths force] => :environment do |_task, args|
    errors = TechnicalMetadataGenerator.generate(druid: args[:druid],
                                                 filepaths: args[:filepaths].split,
                                                 force: args[:force] == 'true')
    if errors.empty?
      puts 'Success'
    else
      puts "Failed: #{errors}"
    end
  end

  desc 'Generate technical metadata from Moab'
  task :generate_for_moab, %i[druid force] => :environment do |_task, args|
    MoabProcessingService.process(druid: args[:druid], force: args[:force] == 'true')
    puts 'Queued'
  end
end
