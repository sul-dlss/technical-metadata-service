# frozen_string_literal: true

# Generates and persists technical metadata.
class TechnicalMetadataJob < ApplicationJob
  queue_as :default

  # @param [String] druid
  # @param [Array<String>] filepaths of files
  # @param [Boolean] force even if md5 match
  def perform(druid:, filepaths:, force: false)
    errors = TechnicalMetadataGenerator.generate(druid: druid, filepaths: filepaths, force: force)

    Honeybadger.notify("Generating technical metadata for #{druid} failed: #{errors}") unless errors.empty?
  end
end
