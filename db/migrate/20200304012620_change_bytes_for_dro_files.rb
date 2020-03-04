class ChangeBytesForDroFiles < ActiveRecord::Migration[6.0]
  def change
    change_column :dro_files, :bytes, :integer, limit: 8
  end
end
