# frozen_string_literal: true

require 'socket'

# Generates and persists technical metadata and updates workflow system.
class TechnicalMetadataWorkflowJob < ApplicationJob
  queue_as :default

  # @param [String] druid
  # @param [Array<FileInfo>] info (filepath, md5) on files
  def perform(druid:, file_infos:, force: false)
    start = Time.zone.now
    errors = TechnicalMetadataGenerator.generate_with_file_info(druid: druid, file_infos: file_infos, force: force)
    if errors.empty?
      log_success(druid: druid, elapsed: Time.zone.now - start)
    else
      log_failure(druid: druid, errors: errors)
    end
  end

  private

  def log_success(druid:, elapsed:)
    client.update_status(druid: druid,
                         workflow: 'accessionWF',
                         process: 'technical-metadata',
                         status: 'completed',
                         elapsed: elapsed,
                         note: "Completed by technical-metadata-service on #{Socket.gethostname}.")
  end

  def log_failure(druid:, errors:)
    client.update_error_status(druid: druid,
                               workflow: 'accessionWF',
                               process: 'technical-metadata',
                               error_msg: 'Problem with technical-metadata-service on ' \
                                          "#{Socket.gethostname}: #{errors}")
  end

  def client
    @client ||= Dor::Workflow::Client.new(url: Settings.workflow.url, logger: Rails.logger)
  end
end
