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

ActiveRecord::Schema.define(version: 2019_12_28_162500) do

  create_table "alerts", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "schedule_id"
    t.index ["schedule_id"], name: "index_alerts_on_schedule_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "cutoff"
    t.boolean "local", default: false
    t.index ["user_id"], name: "index_attendance_records_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "title"
    t.integer "position"
    t.integer "subpage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grades", force: :cascade do |t|
    t.integer "submit_id"
    t.string "assist"
    t.integer "scope"
    t.integer "correctness"
    t.integer "design"
    t.integer "style"
    t.text "comments"
    t.integer "grade"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "mailed_at"
    t.boolean "done", default: false
    t.boolean "public", default: false
    t.integer "calculated_grade"
    t.text "subgrades"
    t.integer "status", default: 0, null: false
    t.integer "grader_id"
    t.text "auto_grades"
    t.text "notes"
    t.index ["submit_id"], name: "index_grades_on_submit_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.integer "schedule_id"
    t.index ["schedule_id"], name: "index_groups_on_schedule_id"
    t.index ["slug"], name: "index_groups_on_slug", unique: true
  end

  create_table "groups_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "group_id"
    t.index ["group_id"], name: "index_groups_users_on_group_id"
    t.index ["user_id"], name: "index_groups_users_on_user_id"
  end

  create_table "hands", force: :cascade do |t|
    t.integer "user_id"
    t.string "location"
    t.text "help_question"
    t.boolean "done", default: false
    t.integer "assist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "note"
    t.string "evaluation"
    t.boolean "success", default: false
    t.boolean "helpline", default: false
    t.string "progress"
    t.datetime "claimed_at"
    t.datetime "closed_at"
    t.string "subject"
    t.index ["assist_id"], name: "index_hands_on_assist_id"
    t.index ["user_id"], name: "index_hands_on_user_id"
  end

  create_table "logins", force: :cascade do |t|
    t.string "login"
    t.integer "user_id"
    t.index ["user_id"], name: "index_logins_on_user_id"
  end

  create_table "mods", force: :cascade do |t|
    t.string "name"
    t.integer "pset_id"
    t.index ["pset_id"], name: "index_mods_on_pset_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "text"
    t.integer "student_id"
    t.integer "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_id"], name: "index_notes_on_author_id"
    t.index ["student_id"], name: "index_notes_on_student_id"
  end

  create_table "pages", force: :cascade do |t|
    t.string "title"
    t.integer "position"
    t.integer "section_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.string "path"
    t.boolean "public", default: false
    t.index ["slug", "section_id"], name: "index_pages_on_slug_and_section_id", unique: true
  end

  create_table "pings", force: :cascade do |t|
    t.integer "user_id"
    t.integer "loca"
    t.integer "locb"
    t.boolean "help", default: false
    t.boolean "active", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "help_question"
    t.index ["user_id"], name: "index_pings_on_user_id"
  end

  create_table "pset_files", force: :cascade do |t|
    t.string "filename"
    t.boolean "required", default: false
    t.integer "pset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["pset_id"], name: "index_pset_files_on_pset_id"
  end

  create_table "psets", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "form", default: false
    t.text "message"
    t.integer "order"
    t.boolean "url", default: false
    t.integer "weight"
    t.integer "grade_type"
    t.text "files"
    t.boolean "automatic", default: false, null: false
    t.text "config"
    t.integer "mod_id"
    t.boolean "test", default: false
    t.index ["mod_id"], name: "index_psets_on_mod_id"
    t.index ["page_id"], name: "index_psets_on_page_id"
  end

  create_table "schedule_spans", force: :cascade do |t|
    t.string "name"
    t.integer "schedule_id"
    t.text "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["schedule_id"], name: "index_schedule_spans_on_schedule_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "current_schedule_span_id"
    t.boolean "self_register", default: false, null: false
    t.boolean "self_service", default: false, null: false
  end

  create_table "schedules_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "schedule_id"
    t.index ["schedule_id"], name: "index_schedules_users_on_schedule_id"
    t.index ["user_id"], name: "index_schedules_users_on_user_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "title"
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.string "path"
    t.boolean "display", default: false
    t.text "content_page"
    t.text "content_links"
    t.index ["slug"], name: "index_sections_on_slug", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.integer "thing_id"
    t.string "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true
  end

  create_table "submits", force: :cascade do |t|
    t.integer "user_id"
    t.integer "pset_id"
    t.datetime "submitted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "url"
    t.string "used_login"
    t.text "submitted_files"
    t.string "folder_name"
    t.text "check_feedback"
    t.text "style_feedback"
    t.text "file_contents"
    t.boolean "auto_graded", default: false, null: false
    t.text "check_results"
    t.string "check_token"
    t.index ["pset_id"], name: "index_submits_on_pset_id"
    t.index ["user_id"], name: "index_submits_on_user_id"
  end

  create_table "subpages", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "position"
    t.integer "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.text "description"
    t.index ["slug"], name: "index_subpages_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "mail"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "group_id"
    t.boolean "done", default: false
    t.boolean "active", default: true
    t.string "term"
    t.string "status"
    t.string "token"
    t.string "attendance", default: "", null: false
    t.datetime "last_seen_at"
    t.datetime "last_spoken_at"
    t.datetime "available"
    t.string "avatar"
    t.text "notes"
    t.integer "questions_count_cache", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.integer "schedule_id"
    t.string "last_known_location"
    t.boolean "alarm", default: false, null: false
    t.datetime "last_submitted_at"
    t.datetime "started_at"
    t.text "grades_cache"
    t.integer "current_module_id"
    t.index ["current_module_id"], name: "index_users_on_current_module_id"
    t.index ["schedule_id"], name: "index_users_on_schedule_id"
  end

end
