# frozen_string_literal: true

require 'uri'

# TechnicalMetadataController provides methods for technical metadata for DRO files.
class TechnicalMetadataController < ApplicationController
  # POST /v1/technical-metadata
  def create
    druid, file_uris = params.require(%i[druid files])
    filepaths = file_uris.map { |file_uri| URI(file_uri).path }
    TechnicalMetadataJob.perform_later(druid: druid, filepaths: filepaths)

    head :ok
  end
end
