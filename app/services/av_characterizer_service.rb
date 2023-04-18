# frozen_string_literal: true

require 'open3'
require 'shellwords'

# Characterizes an A/V file using mediainfo.
class AvCharacterizerService
  class Error < StandardError
  end

  # @param [String] filepath of the image to characterize
  # @return [Hash, Array<Hash>] attributes, array of file part attributes.
  # @raise [AvCharacterizerService::Error]
  def characterize(filepath:)
    output, status = Open3.capture2e('mediainfo', '-f', '--Output=JSON', Shellwords.escape(filepath))
    raise Error, "Characterizing #{filepath} returned #{status.exitstatus}: #{output}" unless status.success?

    extract(output, filepath)
  end

  # @return [String] version of mediainfo
  # @raise [AVCharacterizerService::Error]
  def version
    @version ||= begin
      output, status = Open3.capture2e('mediainfo --Version')
      raise Error, "Getting mediainfo version returned #{status.exitstatus}: #{output}" unless status.success?

      match = output.match(/(v\d+\.\d+)/)
      raise Error, "Cannot extract mediainfo version from: #{output}" if match.nil?

      match[1]
    end
  end

  private

  def extract(output, filepath)
    av_metadata = nil
    tracks = []
    json_output = JSON.parse(output)
    json_output['media']['track'].each do |track|
      case track['@type']
      when 'General'
        av_metadata = extract_general(track)
      when 'Audio'
        tracks << extract_audio(track)
      when 'Video'
        tracks << extract_video(track)
      when 'Other'
        tracks << extract_other(track)
      when 'Text'
        tracks << extract_part(track, 'text')
      end
    end

    raise "Unable to find general track in #{filepath}" if av_metadata.nil?

    [av_metadata, tracks]
  end

  def extract_general(track)
    {}.tap do |metadata|
      metadata[:video_count] = track['VideoCount'].to_i if track['VideoCount'].present?
      metadata[:audio_count] = track['AudioCount'].to_i if track['AudioCount'].present?
      metadata[:other_count] = track['OtherCount'].to_i if track['OtherCount'].present?
      metadata[:file_extension] = track['FileExtension'] if track['FileExtension'].present?
      metadata[:format] = track['Format'] if track['Format'].present?
      metadata[:format_profile] = track['Format_Profile'] if track['Format_Profile'].present?
      metadata[:codec_id] = track['CodecID'] if track['CodecID'].present?
      metadata[:duration] = track['Duration'].to_f if track['Duration'].present?
      metadata[:frame_rate] = track['FrameRate'].to_f if track['FrameRate'].present?
      encoded_date = to_iso_time(track['Encoded_Date'])
      metadata[:encoded_date] = encoded_date if encoded_date
    end
  end

  def extract_audio(track)
    part = extract_part(track, 'audio')
    part[:audio_metadata] = {}.tap do |metadata|
      metadata[:format_profile] = track['Format_Profile'] if track['Format_Profile'].present?
      metadata[:codec_id] = track['CodecID'] if track['CodecID'].present?
      metadata[:channels] = track['Channels'] if track['Channels'].present?
      metadata[:sampling_rate] = track['SamplingRate'].to_i if track['SamplingRate'].present?
      metadata[:bit_depth] = track['BitDepth'].to_i if track['BitDepth'].present?
      metadata[:stream_size] = track['StreamSize'].to_i if track['StreamSize'].present?
    end
    part
  end

  def extract_video(track)
    part = extract_part(track, 'video')
    part[:video_metadata] = {}.tap do |metadata|
      metadata[:format_profile] = track['Format_Profile'] if track['Format_Profile'].present?
      metadata[:codec_id] = track['CodecID'] if track['CodecID'].present?
      metadata[:height] = track['Height'].to_i if track['Height'].present?
      metadata[:width] = track['Width'].to_i if track['Width'].present?
      metadata[:display_aspect_ratio] = track['DisplayAspectRatio'].to_f if track['DisplayAspectRatio'].present?
      metadata[:pixel_aspect_ratio] = track['PixelAspectRatio'].to_f if track['PixelAspectRatio'].present?
      metadata[:frame_rate] = track['FrameRate'].to_f if track['FrameRate'].present?
      metadata[:color_space] = track['ColorSpace'] if track['ColorSpace'].present?
      metadata[:chroma_subsampling] = track['ChromaSubsampling'] if track['ChromaSubsampling'].present?
      metadata[:bit_depth] = track['BitDepth'].to_i if track['BitDepth'].present?
      metadata[:language] = track['Language'] if track['Language'].present?
      metadata[:stream_size] = track['StreamSize'].to_i if track['StreamSize'].present?
      metadata[:standard] = track['Standard'] if track['Standard'].present?
    end
    part
  end

  def extract_other(track)
    part = extract_part(track, 'other')
    part[:other_metadata] = {}.tap do |metadata|
      metadata[:other_type] = track['Type'] if track['Type'].present?
      metadata[:title] = track['Title'] if track['Title'].present?
    end
    part
  end

  def extract_part(track, part_type)
    {
      part_type: part_type,
      part_id: track['ID'].presence,
      order: track['StreamOrder'].present? ? track['StreamOrder'].to_i : nil,
      format: track['Format'].presence,
      audio_metadata: nil,
      video_metadata: nil,
      other_metadata: nil
    }
  end

  # @param [String,nil] time a date with format like 'UTC 2020-02-27 06:06:04' or nil if blank or unparseable.
  # @note time may not include UTC.
  def to_iso_time(time)
    return nil if time.blank?

    time.gsub!(/[:-]/, '') # strips : or - in date and time parts to handle cases where the date has colons or dashes
    date_format = '%Y%m%d %H%M%S%z'
    return Time.strptime("#{time}+0000", date_format).iso8601.delete_suffix('+00:00') unless time.start_with?('UTC')

    Time.strptime("#{time}+0000", "UTC #{date_format}").iso8601
  rescue ArgumentError
    nil
  end
end
