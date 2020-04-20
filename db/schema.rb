# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_04_012620) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "dro_file_parts", force: :cascade do |t|
    t.bigint "dro_file_id"
    t.string "part_type", null: false
    t.string "part_id"
    t.integer "order"
    t.string "format"
    t.jsonb "audio_metadata"
    t.jsonb "video_metadata"
    t.jsonb "other_metadata"
    t.index ["dro_file_id"], name: "index_dro_file_parts_on_dro_file_id"
  end

  create_table "dro_files", force: :cascade do |t|
    t.string "druid", null: false
    t.string "filename", null: false
    t.string "md5", null: false
    t.bigint "bytes", null: false
    t.string "filetype"
    t.jsonb "tool_versions"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "mimetype"
    t.jsonb "pdf_metadata"
    t.jsonb "image_metadata"
    t.datetime "file_modification"
    t.jsonb "av_metadata"
    t.index ["druid", "filename"], name: "index_dro_files_on_druid_and_filename", unique: true
    t.index ["druid"], name: "index_dro_files_on_druid"
    t.index ["filetype"], name: "index_dro_files_on_filetype"
    t.index ["mimetype"], name: "index_dro_files_on_mimetype"
    t.index ["updated_at"], name: "index_dro_files_on_updated_at"
  end

  add_foreign_key "dro_file_parts", "dro_files"
end
