# frozen_string_literal: true

require 'moab'
require 'moab/stanford'

Moab::Config.configure do
  storage_roots(Settings.storage_root_map.default.to_h.values)
  storage_trunk('sdr2objects')
  path_method(:druid_tree)
  # checksum_algos(Settings.checksum_algos.map(&:to_sym))
end
