# frozen_string_literal: true

require 'uri'

# TechnicalMetadataController provides methods for technical metadata for DRO files.
class TechnicalMetadataController < ApiController
  # POST /v1/technical-metadata
  def create
    TechnicalMetadataWorkflowJob.set(queue:).perform_later(druid: params[:druid],
                                                           file_infos: file_create_infos,
                                                           force: force?)

    head :ok
  end

  # GET /v1/technical-metadata/druid/{druid}
  def show_by_druid
    @files = DroFile.where(druid: params[:druid]).order(:filename)
    head(:not_found) if @files.empty?
  end

  # Given a druid (in the URL path) and a list of filename/md5 pairs (in the request body with filename URL encoded),
  # return any differences between the expected (given) file signature list and the actual contents of technical
  # metadata service's DB.
  #
  # @note This is just a read, and so should be idempotent, but we're using a POST instead of a GET, because
  # the parameter list might exceed the traditional 2 kB limit on URL params for a GET request.
  # @note The returned structure is a list of expected filenames that techMD does not know about but
  # should (missing_filenames), a list of filenames for which techMD has info but shouldn't (unexpected_filenames), and
  # a list of files where techMD and the caller each have differing metadata (mismatched_checksum_file_infos, a list of
  # hashes with filename and md5, where the md5 is the one techMD has recorded, since the caller already knows the
  # checksum they provided).
  #
  # POST /v1/technical-metadata/audit/{druid}
  def audit_by_druid
    techmd_dro_files = DroFile.where(druid: params[:druid])
    return head(:not_found) if techmd_dro_files.empty?

    render json: diff(techmd_dro_files:, expected_file_infos: file_audit_infos).to_json
  end

  private

  def diff(techmd_dro_files:, expected_file_infos:)
    recorded_filenames = techmd_dro_files.pluck(:filename)
    expected_filenames = expected_file_infos.pluck(:filename)

    missing_filenames = expected_filenames - recorded_filenames
    unexpected_filenames = recorded_filenames - expected_filenames

    mismatched_checksum_file_infos = expected_file_infos.filter_map do |expected_file|
      techmd_dro_files.where(filename: expected_file[:filename]).where.not(md5: expected_file[:md5]).map do |dro_file|
        dro_file.attributes.slice('filename', 'md5')
      end.presence # if no mismatches are found, []#presence will return nil, and filter_map will discard it
    end.flatten

    { missing_filenames:, unexpected_filenames:, mismatched_checksum_file_infos: }
  end

  def file_create_infos
    params[:files].map do |file|
      filepath = CGI.unescape(URI(file[:uri]).path)
      filename = FilepathSupport.filename_for(filepath:, basepath: params[:basepath])
      FileInfo.new(filepath:, md5: file[:md5], filename:)
    end
  end

  def file_audit_infos
    @file_audit_infos ||=
      params[:expected_files].map do |expected_file|
        { filename: CGI.unescape(expected_file[:filename]), md5: expected_file[:md5] }
      end
  end

  def queue
    params['lane-id'] == 'low' ? :low : :default
  end

  def force?
    params[:force] == true
  end
end
