class CreateDroFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :dro_files do |t|
      t.string :druid, null: false
      t.string :filename, null: false
      t.string :md5, null: false
      t.integer :bytes, null: false
      t.string :filetype
      t.jsonb :tool_versions
      t.timestamps
      t.index [:druid, :filename], unique: true
    end
  end
end
