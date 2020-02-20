class AddImageToDroFile < ActiveRecord::Migration[6.0]
  def change
    add_column :dro_files, :height, :integer
    add_column :dro_files, :width, :integer
  end
end
