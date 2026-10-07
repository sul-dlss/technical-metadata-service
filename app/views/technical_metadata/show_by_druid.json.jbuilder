# frozen_string_literal: true

json.ignore_nil!
json.array! @files, partial: 'technical_metadata/dro_file', as: :dro_file
