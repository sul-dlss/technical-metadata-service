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
        [storage_object_version_path(storage_object_version, path), path]
      end
    end.to_h
  end
  # rubocop:enable Metrics/MethodLength

  # @param [Moab::StorageObjectVersion]
  # @param [String] Path to a file to map for technical metadata generation
  # @return [String] Path to the file in the workspace for technical metadata generation
  # @raise [Moab::FileNotFoundException] if the file is not found in the workspace OR in preservation
  def storage_object_version_path(storage_object_version, path) # rubocop:disable Metrics/AbcSize
    storage_object_version.find_filepath('content', path).to_s
  rescue Moab::FileNotFoundException => e
    file_on_preservation = Settings.preservation_root_map
                                   .flat_map { |preservation_path| Pathname.glob("#{DruidTools::Druid.new(druid, preservation_path).path}/**/#{path}") }
                                   .select(&:file?)
                                   .max_by(&:mtime)
    raise e if file_on_preservation.blank?

    # Move the file from preservation to the workspace
    destination = verify_workspace_path(storage_object_version, File.dirname(path))
    FileUtils.cp(file_on_preservation, destination)

    # Call find_filepath on the storage_object_version again now that the file is in place
    storage_object_version.find_filepath('content', path).to_s
  end

  # @param [Moab::StorageObjectVersion] the current StorageObjectVersion for the druid
  # @param [String] the path to a file for the object
  # @return [Pathname] the workspace destination path to copy the file to.
  def verify_workspace_path(storage_object_version, dir)
    destination = storage_object_version.file_category_pathname('content').join(dir)
    FileUtils.mkdir_p(destination)
    destination
  end
end
