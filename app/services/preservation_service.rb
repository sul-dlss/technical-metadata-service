# frozen_string_literal: true

# Provides retrieval from preservation services
class PreservationService
  def self.copy_file(druid:, filepath:)
    new(druid:, filepath:).copy_file
  end

  # @param [String] druid
  # @param [Boolean] force generation even if md5 match
  def initialize(druid:, filepath:)
    @druid = druid
    @filepath = filepath
  end

  def copy_file
    return false if paths.blank?

    file_on_preservation = storage_object_version.find_filepath('content', paths.first)
    FileUtils.cp(file_on_preservation, filepath)
  rescue Moab::FileNotFoundException
    false
  end

  private

  attr_reader :druid, :filepath

  def storage_object
    Moab::StorageServices.find_storage_object(druid)
  end

  def storage_object_version
    storage_object.find_object_version
  end

  def file_inventory
    storage_object_version.file_inventory('version')
  end

  def content_group
    file_inventory.group('content')
  end

  def paths
    content_group.files.find { |pres_path| pres_path.paths.include? File.basename(filepath) }&.paths
  end
end
