# frozen_string_literal: true

# Digital Repository Object File
class DroFile < ApplicationRecord
  has_many :dro_file_parts, dependent: :destroy

  # Because count is very slow.
  # See https://www.citusdata.com/blog/2016/10/12/count-performance/
  def self.estimated_count
    DroFile.connection.select_all("SELECT n_live_tup FROM pg_stat_all_tables WHERE relname = 'dro_files'")
           .last['n_live_tup']
           .round(-4)
  end
end
