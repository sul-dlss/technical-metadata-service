# frozen_string_literal: true

json.ignore_nil!
json.array! @files, :druid, :filename, :filetype, :mimetype, :bytes, :file_create, :file_modification,
            :height, :width, :pdf_metadata
