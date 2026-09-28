# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_09_28_213756) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "background_check_runs", force: :cascade do |t|
    t.string "candidate_name", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "aliases", default: [], null: false
    t.jsonb "jurisdictions", default: [], null: false
    t.jsonb "search_results", default: [], null: false
    t.integer "searches_expected", default: 0, null: false
    t.integer "searches_completed", default: 0, null: false
    t.boolean "searches_started", default: false, null: false
    t.text "evaluation"
    t.text "comparison"
    t.text "candidate_story"
    t.text "notification"
    t.text "dispute_handling"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
