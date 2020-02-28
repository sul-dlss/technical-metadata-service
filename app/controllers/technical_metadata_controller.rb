# frozen_string_literal: true

require 'uri'

# TechnicalMetadataController provides methods for technical metadata for DRO files.
class TechnicalMetadataController < ApplicationController
  # POST /v1/technical-metadata
  def create
    druid, file_uris = params.require(%i[druid files])
    filepaths = file_uris.map { |file_uri| URI(file_uri).path }
    TechnicalMetadataWorkflowJob.perform_later(druid: druid, filepaths: filepaths)

    head :ok
  end

  # GET /v1/technical-metadata/druid/{druid}
  def show_by_druid
    @files = DroFile.where(druid: params[:druid]).order(:filename)
    return head(:not_found) if @files.empty?
  end
end
