class AddDruidIndexToDroFiles < ActiveRecord::Migration[6.0]
  def change
    add_index :dro_files, :druid
  end
end
