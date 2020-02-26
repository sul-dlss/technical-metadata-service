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

ActiveRecord::Schema.define(version: 2020_02_26_055313) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "dro_files", force: :cascade do |t|
    t.string "druid", null: false
    t.string "filename", null: false
    t.string "md5", null: false
    t.integer "bytes", null: false
    t.string "filetype"
    t.jsonb "tool_versions"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "mimetype"
    t.integer "height"
    t.integer "width"
    t.datetime "file_modification"
    t.datetime "file_create"
    t.index ["druid", "filename"], name: "index_dro_files_on_druid_and_filename", unique: true
    t.index ["druid"], name: "index_dro_files_on_druid"
  end

end
