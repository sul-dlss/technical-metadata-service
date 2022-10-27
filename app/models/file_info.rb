# frozen_string_literal: true

# Information about a file.
class FileInfo
  def initialize(filepath:, md5:, filename:)
    @filepath = filepath
    @md5 = md5
    @filename = filename
  end

  attr_reader :filepath, :md5, :filename

  def ==(other)
    filepath == other.filepath && md5 == other.md5
  end
end
