# frozen_string_literal: true

# Generates and persists technical metadata.
class TechnicalMetadataJob < ApplicationJob
  queue_as :default

  # @param [String] druid
  # @param [Array<String>] filepaths of files
  def perform(druid:, filepaths:)
    errors = TechnicalMetadataGenerator.generate(druid: druid, filepaths: filepaths)

    Honeybadger.notify("Generating technical metadata for #{druid} failed: #{errors}") unless errors.empty?
  end
end
