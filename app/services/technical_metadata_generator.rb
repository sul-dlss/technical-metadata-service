# frozen_string_literal: true

# Generates and persists technical metadata.
class TechnicalMetadataGenerator
  def self.generate(druid:, filepath_map:, force: false)
    new(druid:, force:).generate(filepath_map)
  end

  def self.generate_with_file_info(druid:, file_infos:, force: false)
    new(druid:, force:).generate_with_file_info(file_infos)
  end

  # @param [String] druid
  # @param [Boolean] force generation even if md5 match
  def initialize(druid:, force: false)
    @druid = druid
    @force = force
    @errors = []
    @dro_file_upserts = []
    @dro_file_part_inserts = {}
    @dro_file_deletes = []
  end

  # Generate and persist technical metadata.
  # If any errors are returned, then no changes were made to the existing file model objects.
  # Will exit early after checking that files exist. Otherwise, will return errors after generating technical metadata
  # for all files.
  # @param [Hash<String,String>] map of filepaths of files to filenames
  # @return [Array<String>] errors
  def generate(filepath_map)
    # Check that file exists for every filepath. If it doesn't, add to errors and fail.
    check_files_exist(filepath_map.keys)
    return errors unless errors.empty?

    # Generate technical metadata for each file. If any errors, fail.
    filepath_map.each { |filepath, filename| generate_for_file(filepath, filename) }
    return errors unless errors.empty?

    # Find DroFiles that should be deleted.
    generate_dro_files_deletes(filepath_map.values)

    persist!

    errors
  end

  # Generate and persist technical metadata.
  # Similar to generate() but uses the provided MD5 checksum to determine if the technical metadata
  # needs to be generated.
  # It is not required that all files be present on disk.
  # @param [Array<FileInfo>] info (filepath, md5) on files
  # @return [Array<String>] errors
  def generate_with_file_info(file_infos)
    # Find names without an existing DroFile (matching MD5, filename, druid).
    filepath_map = filepaths_to_generate_for(file_infos)

    # Check that file exists for every filepath. If it doesn't, add to errors and fail.
    check_files_exist(filepath_map.keys)
    return errors unless errors.empty?

    # Generate technical metadata for each file. If any errors, fail.
    filepath_map.each { |filepath, filename| generate_for_file(filepath, filename) }
    return errors unless errors.empty?

    # Find DroFiles that should be deleted.
    filenames = file_infos.map(&:filename)
    generate_dro_files_deletes(filenames)

    persist!

    errors
  end

  private

  attr_reader :druid, :errors, :dro_file_upserts, :dro_file_part_inserts, :force, :dro_file_deletes

  def check_files_exist(filepaths)
    filepaths.each { |filepath| errors << "#{filepath} not found" unless File.exist?(filepath) }
  end

  def filepaths_to_generate_for(file_infos)
    file_infos_to_generate = file_infos.reject do |file_info|
      DroFile.exists?(druid:, filename: file_info.filename, md5: file_info.md5)
    end
    file_infos_to_generate.to_h { |file_info| [file_info.filepath, file_info.filename] }
  end

  def generate_for_file(filepath, filename)
    #   Generate md5 file
    md5 = Digest::MD5.file(filepath).hexdigest
    dro_file = dro_file_for(filename)
    # No need to generate if md5's match.
    return unless generate?(dro_file, md5)

    # Note that when upserting, all object must have same keys
    dro_file_upserts << merged_upsert(upsert_for(filepath, filename, md5), generate_metadata(filepath, filename))
  rescue StandardError => e
    errors << "Error generating for #{filepath} (#{druid}): #{e.message}"
    raise
  end

  def generate_metadata(filepath, filename)
    # Need to provide all keys for upsert, so creating a blank metadata template.
    metadata = { filetype: nil, mimetype: nil, tool_versions: {} }

    if ::File.size(filepath).positive?
      metadata[:filetype], metadata[:mimetype] = file_identifier.identify(filepath:)
      metadata[:tool_versions]['siegfried'] = file_identifier.version
    end

    metadata.deep_merge(generate_metadata_for_mimetype(metadata[:mimetype], filepath, filename))
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def generate_metadata_for_mimetype(mimetype, filepath, filename)
    metadata = { image_metadata: nil, pdf_metadata: nil, av_metadata: nil }

    return metadata if mimetype.nil?

    begin
      if image?(mimetype)
        metadata[:image_metadata] = image_characterizer.characterize(filepath:)
        metadata[:tool_versions] = { 'exiftool' => image_characterizer.version }
      elsif pdf?(mimetype)
        metadata[:pdf_metadata] = pdf_characterizer.characterize(filepath:)
        metadata[:tool_versions] = { 'poppler' => pdf_characterizer.version }
      elsif av?(mimetype)
        metadata[:av_metadata],
        dro_file_part_inserts[filename] = av_characterizer.characterize(filepath:)
        metadata[:tool_versions] = { 'mediainfo' => av_characterizer.version }
      end
    rescue CharacterizationError => e
      Honeybadger.notify(e, context: {
                           druid:,
                           mimetype:,
                           filepath:,
                           filename:,
                           tool_versions: metadata[:tool_versions]
                         })
    end

    metadata
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def dro_file_for(filename)
    DroFile.find_by(druid:, filename:)
  end

  def merged_upsert(dro_upsert, metadata_upsert)
    upsert = dro_upsert.merge(metadata_upsert)
    # Removing null character, which causes ActiveRecord::StatementInvalid: PG::UntranslatableCharacter:
    # ERROR: unsupported Unicode escape sequence DETAIL: \u0000 cannot be converted to text.
    upsert.deep_transform_values { |value| value.is_a?(String) ? value.delete("\u0000") : value }
  end

  def upsert_for(filepath, filename, md5)
    {
      druid:,
      filename:,
      md5:,
      bytes: ::File.size(filepath),
      file_modification: ::File.mtime(filepath),
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    }
  end

  def generate_dro_files_deletes(filenames)
    DroFile.where(druid:).find_each do |dro_file|
      dro_file_deletes << dro_file unless filenames.include?(dro_file.filename)
    end
  end

  def upsert_dro_file(upsert)
    dro_file = DroFile.find_by(druid: upsert[:druid], filename: upsert[:filename])
    if dro_file
      # Removing all of the existing file parts. They will be re-added.
      dro_file.dro_file_parts.destroy_all
      dro_file.update(upsert)
    else
      dro_file = DroFile.create(upsert)
    end
    dro_file
  end

  def insert_dro_file_parts(dro_file)
    return if dro_file_part_inserts[dro_file.filename].blank?

    # Adding the Dro_file's id to the insert.
    dro_file_part_inserts[dro_file.filename].each { |part_insert| part_insert[:dro_file_id] = dro_file.id }
    DroFilePart.insert_all!(dro_file_part_inserts[dro_file.filename])
  end

  def file_identifier
    @file_identifier ||= FileIdentifierService.new
  end

  def image_characterizer
    @image_characterizer ||= ImageCharacterizerService.new
  end

  def pdf_characterizer
    @pdf_characterizer ||= PdfCharacterizerService.new
  end

  def av_characterizer
    @av_characterizer ||= AvCharacterizerService.new
  end

  def image?(mimetype)
    mimetype.start_with?('image/')
  end

  def pdf?(mimetype)
    mimetype == 'application/pdf'
  end

  def av?(mimetype)
    return true if mimetype.start_with?('audio/')
    return true if mimetype.start_with?('video/')
    return true if mimetype == 'application/mp4'

    false
  end

  def generate?(dro_file, md5)
    dro_file.nil? || dro_file.md5 != md5 || force
  end

  def persist!
    ApplicationRecord.transaction do
      dro_file_deletes.each(&:destroy)
      dro_file_upserts.each do |upsert|
        dro_file = upsert_dro_file(upsert)
        insert_dro_file_parts(dro_file)
      end
    end
  end
end
