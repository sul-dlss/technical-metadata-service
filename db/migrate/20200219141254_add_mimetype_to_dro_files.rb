class AddMimetypeToDroFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :dro_files, :mimetype, :string
  end
end
