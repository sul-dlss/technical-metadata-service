# frozen_string_literal: true

require 'open3'

# Identifies a file using Siegfried.
class FileIdentifierService
  class Error < StandardError
  end

  # @param [String] filepath of the file to identify
  # @return [String|nil] mimetype of the file or nil if unknown
  # @raise [FileIdentifierServiceError]
  def identify(filepath:)
    output, status = Open3.capture2e("sf -json #{filepath}")
    raise Error, "Identifying #{filepath} returned #{status.exitstatus}: #{output}" unless status.success?

    extract_mimetype(output, filepath)
  end

  # @return [String] version of Siegfried
  # @raise [FileIdentifierServiceError]
  def version
    @version ||= begin
      output, status = Open3.capture2e('sf -version')
      raise Error, "Getting Siegfried version returned #{status.exitstatus}: #{output}" unless status.success?

      match = output.match(/siegfried (\d+\.\d+\.\d+)/)
      raise Error, "Cannot extract Siegfried version from: #{output}" if match.nil?

      match[1]
    end
  end

  private

  def extract_mimetype(output, filepath)
    json_output = JSON.parse(output)
    json_output['files'].each do |file|
      next unless file['filename'] == filepath

      file['matches'].each do |match|
        next unless match['id'] == 'pronom'

        return match['mime'].presence
      end
    end

    raise Error, "Unable to find file type for #{filepath} in: #{output}"
  end
end
