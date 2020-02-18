# frozen_string_literal: true

# Generates and persists technical metadata.
class TechnicalMetadataGenerator
  def self.generate(druid:, filepaths:)
    new(druid: druid, filepaths: filepaths).generate
  end

  # @param [String] druid
  # @param [Array<String>] filepaths of files
  def initialize(druid:, filepaths:)
    @druid = druid
    @filepaths = filepaths
    @errors = []
    @upserts = []
  end

  # Generate and persist technical metadata.
  # If any errors are returned, then no changes were made to the existing file model objects.
  # Will exit early after checking that files exist. Otherwise, will return errors after generating technical metadata
  # for all files.
  # @return [Array<String>] errors
  # rubocop:disable Metrics/AbcSize
  def generate
    # Check that file exists for every filepath. If it doesn't, add to errors and fail.
    check_files_exist
    return errors unless errors.empty?

    # Generate technical metadata for each file. If any errors, fail.
    filepaths.each { |filepath| generate_for_file(filepath) }
    return errors unless errors.empty?

    # Find DroFiles that should be deleted.
    to_delete = dro_files_to_delete

    ApplicationRecord.transaction do
      to_delete.each(&:destroy)
      DroFile.upsert_all(upserts, unique_by: %i[druid filename])
    end

    errors
  end
  # rubocop:enable Metrics/AbcSize

  private

  attr_reader :druid, :filepaths, :errors, :upserts

  def check_files_exist
    filepaths.each { |filepath| errors << "#{filepath} not found" unless File.exist?(filepath) }
  end

  def generate_for_file(filepath)
    #   Generate md5 file
    md5 = Digest::MD5.file(filepath).hexdigest
    dro_file = dro_file_for(filepath)
    # No need to generate if md5's match.
    return if dro_file && dro_file.md5 == md5

    upserts << upsert_for(filepath, md5).merge(generate_metadata(filepath))
  rescue StandardError => e
    errors << "Error generating for #{filepath} (#{druid}): #{e.message}"
    raise
  end

  def generate_metadata(_filepath)
    # TODO
    {
      filetype: 'TBD',
      tool_versions: {
        'TBD' => '1.0.0'
      }
    }
  end

  def filename_for(filepath)
    ::File.basename(filepath)
  end

  def dro_file_for(filepath)
    DroFile.find_by(druid: druid, filename: filename_for(filepath))
  end

  def upsert_for(filepath, md5)
    {
      druid: druid,
      filename: filename_for(filepath),
      md5: md5,
      bytes: ::File.size(filepath),
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    }
  end

  def dro_files_to_delete
    to_delete = []
    DroFile.where(druid: druid).find_each do |dro_file|
      to_delete << dro_file unless filenames.include?(dro_file.filename)
    end
    to_delete
  end

  def filenames
    @filenames ||= filepaths.map { |filepath| filename_for(filepath) }
  end
end
