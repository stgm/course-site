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

ActiveRecord::Schema.define(version: 20150713122940) do

  create_table "alerts", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.boolean  "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "answers", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "answer_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pset_id"
  end

  add_index "answers", ["user_id"], name: "index_answers_on_user_id"

  create_table "categories", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.integer  "position"
    t.integer  "subpage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grades", force: :cascade do |t|
    t.integer  "submit_id"
    t.string   "grader",      limit: 255
    t.integer  "scope"
    t.integer  "correctness"
    t.integer  "design"
    t.integer  "style"
    t.text     "comments"
    t.integer  "grade"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "mailed_at",               default: '-4712-01-01 00:00:00', null: false
  end

  add_index "grades", ["submit_id"], name: "index_grades_on_submit_id"

  create_table "groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.integer  "position"
    t.integer  "section_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",       limit: 255
    t.string   "path",       limit: 255
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
    t.string   "filename",   limit: 255
    t.boolean  "required"
    t.integer  "pset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pset_files", ["pset_id"], name: "index_pset_files_on_pset_id"

  create_table "psets", force: :cascade do |t|
    t.string   "name",        limit: 255
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

  create_table "psets_tracks", force: :cascade do |t|
    t.integer "pset_id"
    t.integer "track_id"
  end

  add_index "psets_tracks", ["track_id", "pset_id"], name: "index_psets_tracks_on_track_id_and_pset_id"
  add_index "psets_tracks", ["track_id"], name: "index_psets_tracks_on_track_id"

  create_table "registrations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "track_id"
    t.string   "term",             limit: 255
    t.string   "status",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "schedule_id"
    t.integer  "schedule_span_id"
  end

  add_index "registrations", ["track_id"], name: "index_registrations_on_track_id"
  add_index "registrations", ["user_id"], name: "index_registrations_on_user_id"

  create_table "schedule_spans", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.integer  "schedule_id"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "schedule_spans", ["schedule_id"], name: "index_schedule_spans_on_schedule_id"

  create_table "schedules", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.integer  "track_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "schedules", ["track_id"], name: "index_schedules_on_track_id"

  create_table "sections", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",       limit: 255
    t.string   "path",       limit: 255
  end

  add_index "sections", ["slug"], name: "index_sections_on_slug", unique: true

  create_table "settings", force: :cascade do |t|
    t.string   "var",        limit: 255, null: false
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
    t.string   "url",          limit: 255
  end

  add_index "submits", ["pset_id"], name: "index_submits_on_pset_id"
  add_index "submits", ["user_id"], name: "index_submits_on_user_id"

  create_table "subpages", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.text     "content"
    t.integer  "position"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",       limit: 255
  end

  add_index "subpages", ["slug"], name: "index_subpages_on_slug", unique: true

  create_table "tracks", force: :cascade do |t|
    t.integer  "final_grade_id"
    t.string   "name",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "uvanetid",         limit: 255
    t.string   "mail",             limit: 255
    t.string   "avatar",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
    t.boolean  "done",                         default: false
    t.boolean  "active",                       default: true
    t.string   "term",             limit: 255
    t.string   "status",           limit: 255
    t.integer  "schedule_id"
    t.integer  "schedule_span_id"
    t.string   "token",            limit: 255
  end

  add_index "users", ["schedule_id"], name: "index_users_on_schedule_id"
  add_index "users", ["schedule_span_id"], name: "index_users_on_schedule_span_id"

end
