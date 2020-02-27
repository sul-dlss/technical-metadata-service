class AddImageMetadataToDroFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :dro_files, :image_metadata, :jsonb
    remove_column :dro_files, :height, :integer
    remove_column :dro_files, :width, :integer
  end
end
