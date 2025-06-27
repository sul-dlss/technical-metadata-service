# frozen_string_literal: true

require 'socket'

# Generates and persists technical metadata and updates workflow system.
class TechnicalMetadataWorkflowJob < ApplicationJob
  queue_as :default

  # @param [String] druid
  # @param [Array<FileInfo>] info (filepath, md5) on files
  def perform(druid:, file_infos:, force: false)
    start = Time.zone.now
    errors = TechnicalMetadataGenerator.generate_with_file_info(druid:, file_infos:, force:)
    if errors.empty?
      log_success(druid:, elapsed: Time.zone.now - start)
    else
      log_failure(druid:, errors:)
    end
  rescue StandardError => e # put workflow step into an error state before sending to HB
    log_failure(druid:, errors: e.message)
    Honeybadger.notify(e)
  end

  private

  def log_success(druid:, elapsed:)
    note = "Completed by technical-metadata-service on #{Socket.gethostname}."
    Dor::Services::Client.object(druid).workflow(workflow).process(process)
                         .update(status: 'completed',
                                 elapsed:,
                                 note:)
  end

  def log_failure(druid:, errors:)
    error_msg = "Problem with technical-metadata-service on #{Socket.gethostname}: #{errors}"
    Dor::Services::Client.object(druid).workflow(workflow).process(process).update_error(error_msg:)
  end

  def workflow
    'accessionWF'
  end

  def process
    'technical-metadata'
  end
end
