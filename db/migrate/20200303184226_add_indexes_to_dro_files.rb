class AddIndexesToDroFiles < ActiveRecord::Migration[6.0]
  def change
    add_index :dro_files, :mimetype
    add_index :dro_files, :filetype
    add_index :dro_files, :updated_at
  end
end
