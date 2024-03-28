# frozen_string_literal: true

namespace :techmd do
  desc 'Generate technical metadata (synchronously) from druid + filepaths'
  task :generate, %i[druid filepaths basepath force] => :environment do |_task, args|
    filepath_map = FilepathSupport.filepath_map_for(filepaths: args[:filepaths].split(','), basepath: args[:basepath])
    errors = TechnicalMetadataGenerator.generate(druid: args[:druid],
                                                 filepath_map:,
                                                 force: args[:force] == 'true')
    if errors.empty?
      puts 'Success'
    else
      puts "Failed: #{errors}"
    end
  end

  desc 'Create job to generate technical metadata from Moab'
  task :generate_for_moab, %i[druid force] => :environment do |_task, args|
    MoabProcessingService.process(druid: args[:druid], force: args[:force] == 'true')
    puts 'Queued'
  end

  desc 'Create jobs to generate technical metadata from Moabs by druid list (druids.txt)'
  task :generate_for_moab_list, %i[force] => :environment do |_task, args|
    force = args[:force] == 'true'
    File.foreach('druids.txt').map(&:strip).each_with_index do |druid, index|
      if !force && DroFile.exists?(druid:)
        puts "Skipped #{druid} (#{index + 1}) since already has technical metadata"
      elsif MoabProcessingService.process(druid:, force:)
        puts "Queued #{druid} (#{index + 1})"
      else
        puts "Skipped #{druid} (#{index + 1}) since no content"
      end
    end
  end

  namespace :reports do
    desc 'Output a CSV of media durations for corresponding druids'
    task :media_durations, %i[input_path] => :environment do |_task, args|
      results = File.foreach(args[:input_path], chomp: true).flat_map do |druid|
        DroFile.where(druid:)
               .order(:filename)
               .filter_map do |dro_file|
          next if dro_file.av_metadata.blank?

          "#{druid},#{dro_file.filename},#{dro_file.mimetype},#{dro_file.bytes}," \
            "#{dro_file.av_metadata.fetch('duration', 'none recorded')}"
        end
      end
      puts results.join("\n")
    end
  end
end
