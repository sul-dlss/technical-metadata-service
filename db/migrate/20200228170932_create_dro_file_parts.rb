class CreateDroFileParts < ActiveRecord::Migration[6.0]
  def change
    create_table :dro_file_parts do |t|
      t.belongs_to :dro_file, foreign_key: true
      t.string :part_type, null: false
      t.string :part_id
      t.integer :order
      t.string :format
      t.jsonb :audio_metadata
      t.jsonb :video_metadata
      t.jsonb :other_metadata
    end
    add_column :dro_files, :av_metadata, :jsonb
  end
end
