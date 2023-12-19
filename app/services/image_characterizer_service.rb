# frozen_string_literal: true

require 'open3'

# Characterizes an image using exiftool.
class ImageCharacterizerService
  class Error < CharacterizationError
  end

  # @param [String] filepath of the image to characterize
  # @return [Hash] attributes including height and width
  # @raise [ImageCharacterizerService::Error]
  def characterize(filepath:)
    output, err, status = Open3.capture3('exiftool', '-ImageHeight', '-ImageWidth', '-json', filepath)
    raise Error, "Characterizing #{filepath} returned #{status.exitstatus}: #{err}\n#{output}" unless status.success?

    extract_attributes(output, filepath)
  end

  # @return [String] version of exiftool
  # @raise [ImageCharacterizerService::Error]
  def version
    @version ||= begin
      output, status = Open3.capture2e('exiftool -ver')
      raise Error, "Getting exiftool version returned #{status.exitstatus}: #{output}" unless status.success?

      match = output.match(/(\d+\.\d+)/)
      raise Error, "Cannot extract exiftool version from: #{output}" if match.nil?

      match[1]
    end
  end

  private

  def extract_attributes(output, filepath)
    json_output = JSON.parse(output)
    json_output.each do |file|
      next unless file['SourceFile'] == filepath

      attributes = {}.tap do |metadata|
        metadata[:height] = file['ImageHeight'] unless file['ImageHeight'].nil?
        metadata[:width] = file['ImageWidth'] unless file['ImageWidth'].nil?
      end
      return attributes.presence
    end

    raise Error, "Unable to find image attributes for #{filepath} in: #{output}"
  end
end
