# frozen_string_literal: true

# Helper methods for filepaths.
class FilepathSupport
  def self.filename_for(filepath:, basepath:)
    Pathname.new(filepath).relative_path_from(basepath).to_s
  end

  def self.filepath_map_for(filepaths:, basepath:)
    filepaths.index_with { |filepath| filename_for(filepath: filepath, basepath: basepath) }
  end
end
