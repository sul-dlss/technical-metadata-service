# frozen_string_literal: true

# Queues metadata generation for files stored as moabs.
class MoabProcessingService
  def self.process(druid:, force: false)
    new(druid:, force:).process
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
  def process # rubocop:disable Naming/PredicateMethod
    filepath_map = generate_filepath_map
    return false if filepath_map.empty?

    TechnicalMetadataJob.set(queue:).perform_later(druid:, filepath_map:, force:)
    true
  end

  private

  attr_reader :druid, :force, :queue

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def generate_filepath_map
    storage_object = Moab::StorageServices.find_storage_object(druid)
    unless storage_object.object_pathname.exist?
      Honeybadger.notify("Generating technical metadata for #{druid} failed: Moab not found")
      return {}
    end

    storage_object_version = storage_object.find_object_version
    file_inventory = storage_object_version.file_inventory('version')
    content_group = file_inventory.group('content')
    # A collection or no content.
    return {} unless content_group

    content_group.files.flat_map do |file|
      file.paths.map do |path|
        [storage_object_version.find_filepath('content', path).to_s, path]
      end
    end.to_h
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
