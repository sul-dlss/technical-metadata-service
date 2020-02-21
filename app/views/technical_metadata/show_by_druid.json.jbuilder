# frozen_string_literal: true

json.ignore_nil!
json.array! @files, :druid, :filename, :filetype, :mimetype, :bytes, :height, :width
