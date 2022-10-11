# frozen_string_literal: true

# Generates and persists technical metadata.
class TechnicalMetadataGenerator
  def self.generate(druid:, filepaths:, force: false)
    new(druid: druid, force: force).generate(filepaths)
  end

  def self.generate_with_file_info(druid:, file_infos:, force: false)
    new(druid: druid, force: force).generate_with_file_info(file_infos)
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
  # @param [Array<String>] filepaths of files
  # @return [Array<String>] errors
  def generate(filepaths)
    # Check that file exists for every filepath. If it doesn't, add to errors and fail.
    check_files_exist(filepaths)
    return errors unless errors.empty?

    # Generate technical metadata for each file. If any errors, fail.
    filepaths.each { |filepath| generate_for_file(filepath) }
    return errors unless errors.empty?

    # Find DroFiles that should be deleted.
    filenames = filepaths.map { |filepath| filename_for(filepath) }
    generate_dro_files_deletes(filenames)

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
    filepaths = filepaths_to_generate_for(file_infos)

    # Check that file exists for every filepath. If it doesn't, add to errors and fail.
    check_files_exist(filepaths)
    return errors unless errors.empty?

    # Generate technical metadata for each file. If any errors, fail.
    filepaths.each { |filepath| generate_for_file(filepath) }
    return errors unless errors.empty?

    # Find DroFiles that should be deleted.
    filenames = file_infos.map { |file_info| filename_for(file_info.filepath) }
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
      DroFile.exists?(druid: druid, filename: filename_for(file_info.filepath), md5: file_info.md5)
    end
    file_infos_to_generate.map(&:filepath)
  end

  def generate_for_file(filepath)
    #   Generate md5 file
    md5 = Digest::MD5.file(filepath).hexdigest
    dro_file = dro_file_for(filepath)
    # No need to generate if md5's match.
    return unless generate?(dro_file, md5)

    # Note that when upserting, all object must have same keys
    dro_file_upserts << merged_upsert(upsert_for(filepath, md5), generate_metadata(filepath))
  rescue StandardError => e
    errors << "Error generating for #{filepath} (#{druid}): #{e.message}"
    raise
  end

  def generate_metadata(filepath)
    # Need to provide all keys for upsert, so creating a blank metadata template.
    metadata = { filetype: nil, mimetype: nil, tool_versions: {} }

    if ::File.size(filepath).positive?
      metadata[:filetype], metadata[:mimetype] = file_identifier.identify(filepath: filepath)
      metadata[:tool_versions]['siegfried'] = file_identifier.version
    end

    metadata.deep_merge(generate_metadata_for_mimetype(metadata[:mimetype], filepath))
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def generate_metadata_for_mimetype(mimetype, filepath)
    metadata = { image_metadata: nil, pdf_metadata: nil, av_metadata: nil }

    return metadata if mimetype.nil?

    if image?(mimetype)
      metadata[:image_metadata] = image_characterizer.characterize(filepath: filepath)
      metadata[:tool_versions] = { 'exiftool' => image_characterizer.version }
    elsif pdf?(mimetype)
      metadata[:pdf_metadata] = pdf_characterizer.characterize(filepath: filepath)
      metadata[:tool_versions] = { 'poppler' => pdf_characterizer.version }
    elsif av?(mimetype)
      metadata[:av_metadata],
          dro_file_part_inserts[filename_for(filepath)] = av_characterizer.characterize(filepath: filepath)
      metadata[:tool_versions] = { 'mediainfo' => av_characterizer.version }
    end

    metadata
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def filename_for(filepath)
    # For example, /dor/workspace/cy/002/pz/9778/cy002pz9778/content/dir/file.txt
    filepath.gsub(%r{^.+?/content/}, '')
  end

  def dro_file_for(filepath)
    DroFile.find_by(druid: druid, filename: filename_for(filepath))
  end

  def merged_upsert(dro_upsert, metadata_upsert)
    upsert = dro_upsert.merge(metadata_upsert)
    # Removing null character, which causes ActiveRecord::StatementInvalid: PG::UntranslatableCharacter:
    # ERROR: unsupported Unicode escape sequence DETAIL: \u0000 cannot be converted to text.
    upsert.deep_transform_values { |value| value.is_a?(String) ? value.delete("\u0000") : value }
  end

  def upsert_for(filepath, md5)
    {
      druid: druid,
      filename: filename_for(filepath),
      md5: md5,
      bytes: ::File.size(filepath),
      file_modification: ::File.mtime(filepath),
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    }
  end

  def generate_dro_files_deletes(filenames)
    DroFile.where(druid: druid).find_each do |dro_file|
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
