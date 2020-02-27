class DropFileCreateFromDroFiles < ActiveRecord::Migration[6.0]
  def change
    remove_column :dro_files, :file_create, :datetime
  end
end
