# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160818072614) do

  create_table "alerts", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.boolean  "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "attendance_records", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "cutoff"
  end

  add_index "attendance_records", ["user_id"], name: "index_attendance_records_on_user_id"

  create_table "categories", force: :cascade do |t|
    t.string   "title"
    t.integer  "position"
    t.integer  "subpage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grades", force: :cascade do |t|
    t.integer  "submit_id"
    t.string   "grader"
    t.integer  "scope"
    t.integer  "correctness"
    t.integer  "design"
    t.integer  "style"
    t.text     "comments"
    t.integer  "grade"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "mailed_at",                        null: false
    t.boolean  "done",             default: false
    t.boolean  "public",           default: false
    t.integer  "calculated_grade"
  end

  add_index "grades", ["submit_id"], name: "index_grades_on_submit_id"

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hands", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "location"
    t.text     "help_question"
    t.boolean  "done",          default: false
    t.integer  "assist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "note"
    t.string   "evaluation"
  end

  create_table "logins", force: :cascade do |t|
    t.string  "login"
    t.integer "user_id"
  end

  add_index "logins", ["user_id"], name: "index_logins_on_user_id"

  create_table "pages", force: :cascade do |t|
    t.string   "title"
    t.integer  "position"
    t.integer  "section_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "path"
    t.boolean  "public",     default: false
  end

  add_index "pages", ["slug", "section_id"], name: "index_pages_on_slug_and_section_id", unique: true

  create_table "pings", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "loca"
    t.integer  "locb"
    t.boolean  "help"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "help_question"
  end

  add_index "pings", ["user_id"], name: "index_pings_on_user_id"

  create_table "pset_files", force: :cascade do |t|
    t.string   "filename"
    t.boolean  "required"
    t.integer  "pset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pset_files", ["pset_id"], name: "index_pset_files_on_pset_id"

  create_table "psets", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "form"
    t.text     "message"
    t.integer  "order"
    t.boolean  "url"
    t.integer  "weight"
    t.integer  "grade_type"
  end

  add_index "psets", ["page_id"], name: "index_psets_on_page_id"

  create_table "schedule_spans", force: :cascade do |t|
    t.string   "name"
    t.integer  "schedule_id"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "schedule_spans", ["schedule_id"], name: "index_schedule_spans_on_schedule_id"

  create_table "schedules", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sections", force: :cascade do |t|
    t.string   "title"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "path"
  end

  add_index "sections", ["slug"], name: "index_sections_on_slug", unique: true

  create_table "settings", force: :cascade do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true

  create_table "submits", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "pset_id"
    t.datetime "submitted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.string   "used_login"
  end

  add_index "submits", ["pset_id"], name: "index_submits_on_pset_id"
  add_index "submits", ["user_id"], name: "index_submits_on_user_id"

  create_table "subpages", force: :cascade do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "position"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "subpages", ["slug"], name: "index_subpages_on_slug", unique: true

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "mail"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
    t.boolean  "done",           default: false
    t.boolean  "active",         default: true
    t.string   "term"
    t.string   "status"
    t.string   "token"
    t.string   "attendance"
    t.datetime "last_seen_at"
    t.datetime "last_spoken_at"
    t.datetime "available"
  end

end
