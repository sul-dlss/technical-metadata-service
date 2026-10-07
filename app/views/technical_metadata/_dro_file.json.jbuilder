# frozen_string_literal: true

json.call(dro_file, :druid, :filename, :filetype, :mimetype, :bytes, :file_modification, :image_metadata,
          :pdf_metadata, :av_metadata)
if dro_file.dro_file_parts.present?
  json.dro_file_parts do
    json.array! dro_file.dro_file_parts, :part_type, :part_id, :order, :format, :audio_metadata,
                :video_metadata, :other_metadata
  end
end
