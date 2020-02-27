# frozen_string_literal: true

json.ignore_nil!
json.array! @files, :druid, :filename, :filetype, :mimetype, :bytes, :file_modification,
            :image_metadata, :pdf_metadata
