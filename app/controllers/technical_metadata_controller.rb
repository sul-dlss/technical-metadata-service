# frozen_string_literal: true

require 'uri'

# TechnicalMetadataController provides methods for technical metadata for DRO files.
class TechnicalMetadataController < ApiController
  # POST /v1/technical-metadata
  def create
    TechnicalMetadataWorkflowJob.set(queue: queue).perform_later(druid: params[:druid], file_infos: file_infos,
                                                                 force: force?)

    head :ok
  end

  # GET /v1/technical-metadata/druid/{druid}
  def show_by_druid
    @files = DroFile.where(druid: params[:druid]).order(:filename)
    return head(:not_found) if @files.empty?
  end

  private

  def file_infos
    params[:files].map do |file|
      FileInfo.new(filepath: CGI.unescape(URI(file[:uri]).path), md5: file[:md5])
    end
  end

  def queue
    params['lane-id'] == 'low' ? :low : :default
  end

  def force?
    params[:force] == true
  end
end
