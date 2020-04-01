# frozen_string_literal: true

require 'open3'

# Characterizes a PDF using Poppler.
class PdfCharacterizerService
  class Error < StandardError
  end

  # @param [String] filepath of the image to characterize
  # @return [Hash] attributes including pdf_version, pages, page_size, tagged_encrypted, javascript,
  #   form, creator, producer
  # @raise [PdfCharacterizerService::Error]
  def characterize(filepath:)
    output, status = Open3.capture2e('pdfinfo', filepath)
    raise Error, "Characterizing #{filepath} returned #{status.exitstatus}: #{output}" unless status.success?

    extract_attributes(output).merge(text: text?(filepath))
  end

  # @return [String] version of poppler
  # @raise [PdfCharacterizerService::Error]
  def version
    @version ||= begin
      output, status = Open3.capture2e('pdfinfo -v')
      raise Error, "Getting poppler version returned #{status.exitstatus}: #{output}" unless status.success?

      match = output.match(/pdfinfo version (\d+\.\d+\.\d+)/)
      raise Error, "Cannot extract poppler version from: #{output}" if match.nil?

      match[1]
    end
  end

  private

  def text?(filepath)
    output, status = Open3.capture2e('pdftotext', filepath, '-')
    raise Error, "Extracting text from #{filepath} returned #{status.exitstatus}: #{output}" unless status.success?

    output.present?
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def extract_attributes(output)
    attributes = {}
    output.each_line(chomp: true) do |line|
      key, value = line.split(/: */)
      case key
      when 'PDF version'
        attributes[:pdf_version] = value
      when 'Pages'
        attributes[:pages] = value.to_i
      when 'Page size'
        attributes[:page_size] = value
      when 'Tagged'
        attributes[:tagged] = value == 'yes'
      when 'Encrypted'
        attributes[:encrypted] = value == 'yes'
      when 'Javascript'
        attributes[:javascript] = value == 'yes'
      when 'Form'
        attributes[:form] = value != 'none'
      when 'Creator'
        attributes[:creator] = value
      when 'Producer'
        attributes[:producer] = value
      end
    end
    attributes
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
end
