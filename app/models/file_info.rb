# frozen_string_literal: true

# Information about a file.
class FileInfo
  def initialize(filepath:, md5:)
    @filepath = filepath
    @md5 = md5
  end

  attr_reader :filepath, :md5

  def ==(other)
    filepath == other.filepath && md5 == other.md5
  end
end
