# frozen_string_literal: true

# Queues metadata generation for files stored as moabs.
class MoabProcessingService
  def self.process(druid:)
    new(druid: druid).process
  end

  # @param [String] druid
  def initialize(druid:)
    @druid = druid
  end

  def process
    TechnicalMetadataJob.perform_later(druid: druid, filepaths: filepaths)
  end

  private

  attr_reader :druid

  def filepaths
    storage_object = Moab::StorageServices.find_storage_object(druid)
    storage_object_version = storage_object.find_object_version
    file_inventory = storage_object_version.file_inventory('version')
    content_group = file_inventory.group('content')
    content_group.files.map do |file|
      file.paths.map do |path|
        storage_object_version.find_filepath('content', path).to_s
      end
    end.flatten
  end
end
