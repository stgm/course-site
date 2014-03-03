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

ActiveRecord::Schema.define(version: 20140221115415) do

  create_table "answers", force: true do |t|
    t.integer  "user_id"
    t.text     "answer_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pset_id"
  end

  add_index "answers", ["user_id"], name: "index_answers_on_user_id"

  create_table "categories", force: true do |t|
    t.string   "title"
    t.integer  "position"
    t.integer  "subpage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comment_threads", force: true do |t|
    t.string   "title"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: true do |t|
    t.text     "content"
    t.text     "orig_content"
    t.integer  "comment_thread_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grades", force: true do |t|
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
  end

  add_index "grades", ["submit_id"], name: "index_grades_on_submit_id"

  create_table "groups", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", force: true do |t|
    t.string   "title"
    t.integer  "position"
    t.string   "reference"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", force: true do |t|
    t.string   "title"
    t.integer  "position"
    t.integer  "section_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "path"
  end

  add_index "pages", ["slug", "section_id"], name: "index_pages_on_slug_and_section_id", unique: true

  create_table "progresses", force: true do |t|
    t.integer  "user_id"
    t.integer  "page_id"
    t.boolean  "done"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pset_files", force: true do |t|
    t.string   "filename"
    t.boolean  "required"
    t.integer  "pset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pset_files", ["pset_id"], name: "index_pset_files_on_pset_id"

  create_table "psets", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "form"
    t.text     "message"
  end

  add_index "psets", ["page_id"], name: "index_psets_on_page_id"

  create_table "psets_tracks", force: true do |t|
    t.integer "pset_id"
    t.integer "track_id"
  end

  add_index "psets_tracks", ["track_id", "pset_id"], name: "index_psets_tracks_on_track_id_and_pset_id"
  add_index "psets_tracks", ["track_id"], name: "index_psets_tracks_on_track_id"

  create_table "registrations", force: true do |t|
    t.integer  "user_id"
    t.integer  "track_id"
    t.string   "term"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "registrations", ["track_id"], name: "index_registrations_on_track_id"
  add_index "registrations", ["user_id"], name: "index_registrations_on_user_id"

  create_table "sections", force: true do |t|
    t.string   "title"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "path"
  end

  add_index "sections", ["slug"], name: "index_sections_on_slug", unique: true

  create_table "settings", force: true do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true

  create_table "submits", force: true do |t|
    t.integer  "user_id"
    t.integer  "pset_id"
    t.datetime "submitted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "submits", ["pset_id"], name: "index_submits_on_pset_id"
  add_index "submits", ["user_id"], name: "index_submits_on_user_id"

  create_table "subpages", force: true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "position"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "subpages", ["slug"], name: "index_subpages_on_slug", unique: true

  create_table "tracks", force: true do |t|
    t.integer  "final_grade_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "uvanetid"
    t.string   "mail"
    t.string   "avatar"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
    t.boolean  "done",       default: false
    t.boolean  "active",     default: true
  end

end
