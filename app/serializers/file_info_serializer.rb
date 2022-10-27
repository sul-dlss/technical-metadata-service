# frozen_string_literal: true

# Serializer for FileInfos
class FileInfoSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.is_a? FileInfo
  end

  def serialize(file_info)
    super(
      'filepath' => file_info.filepath,
      'md5' => file_info.md5,
      'filename' => file_info.filename
    )
  end

  def deserialize(hash)
    FileInfo.new(filepath: hash['filepath'], md5: hash['md5'], filename: hash['filename'])
  end
end
