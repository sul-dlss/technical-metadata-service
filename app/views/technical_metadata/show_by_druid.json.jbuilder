# frozen_string_literal: true

json.ignore_nil!
json.array! @files do |file|
  json.call(file, :druid, :filename, :filetype, :mimetype, :bytes, :file_modification, :image_metadata,
            :pdf_metadata, :av_metadata)
  unless file.dro_file_parts.empty?
    json.dro_file_parts do
      json.array! file.dro_file_parts, :part_type, :part_id, :order, :format, :audio_metadata,
                  :video_metadata, :other_metadata
    end
  end
end
