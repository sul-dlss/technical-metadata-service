class AddFileDatesToDroFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :dro_files, :file_modification, :datetime
    add_column :dro_files, :file_create, :datetime
  end
end
