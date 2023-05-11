# frozen_string_literal: true

# Generates and persists technical metadata.
class TechnicalMetadataJob < ApplicationJob
  queue_as :default

  # @param [String] druid
  # @param [Hash<String, String>] map of filepaths of files to filenames
  # @param [Boolean] force even if md5 match
  def perform(druid:, filepath_map:, force: false)
    errors = TechnicalMetadataGenerator.generate(druid:, filepath_map:, force:)

    Honeybadger.notify("Generating technical metadata for #{druid} failed: #{errors}") unless errors.empty?
  end
end
