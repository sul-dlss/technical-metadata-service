class AddPdfMetadataToDroFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :dro_files, :pdf_metadata, :jsonb
  end
end
