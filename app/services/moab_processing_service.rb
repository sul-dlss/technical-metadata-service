# frozen_string_literal: true

# Queues metadata generation for files stored as moabs.
class MoabProcessingService
  def self.process(druid:, force: false)
    new(druid: druid, force: force).process
  end

  # @param [String] druid
  # @param [Boolean] force even if md5 match
  # @param [Symbol] queue
  def initialize(druid:, force: false, queue: :retro)
    @druid = druid
    @force = force
    @queue = queue
  end

  # @return [Boolean] true if a job was queued.
  def process
    filepaths = find_filepaths
    return false if filepaths.empty?

    TechnicalMetadataJob.set(queue: queue).perform_later(druid: druid, filepaths: filepaths, force: force)
    true
  end

  private

  attr_reader :druid, :force, :queue

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def find_filepaths
    storage_object = Moab::StorageServices.find_storage_object(druid)
    unless storage_object.object_pathname.exist?
      Honeybadger.notify("Generating technical metadata for #{druid} failed: Moab not found")
      return []
    end

    storage_object_version = storage_object.find_object_version
    file_inventory = storage_object_version.file_inventory('version')
    content_group = file_inventory.group('content')
    # A collection or no content.
    return [] unless content_group

    content_group.files.map do |file|
      file.paths.map do |path|
        storage_object_version.find_filepath('content', path).to_s
      end
    end.flatten
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
