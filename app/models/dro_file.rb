# frozen_string_literal: true

# Digital Repository Object File
class DroFile < ApplicationRecord
  has_many :dro_file_parts, dependent: :destroy
end
