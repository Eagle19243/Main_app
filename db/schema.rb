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

ActiveRecord::Schema.define(version: 20160311012437) do

  create_table "activities", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "action"
    t.integer  "targetable_id"
    t.string   "targetable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "activities", ["targetable_type", "targetable_id"], name: "index_activities_on_targetable_type_and_targetable_id"
  add_index "activities", ["user_id"], name: "index_activities_on_user_id"

  create_table "assignments", force: :cascade do |t|
    t.integer  "task_id"
    t.integer  "user_id"
    t.boolean  "free"
    t.datetime "deadline"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "assignments", ["task_id", "user_id"], name: "index_assignments_on_task_id_and_user_id"

  create_table "conversations", force: :cascade do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "do_for_frees", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "task_id"
    t.string   "state"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "application"
  end

  create_table "do_requests", force: :cascade do |t|
    t.integer  "task_id"
    t.string   "state"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "application"
    t.boolean  "free"
  end

  add_index "do_requests", ["task_id", "user_id"], name: "index_do_requests_on_task_id_and_user_id"

  create_table "institutions", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.string   "country"
    t.string   "city"
    t.string   "logo"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text     "body"
    t.integer  "conversation_id"
    t.integer  "user_id"
    t.boolean  "read",            default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["conversation_id"], name: "index_messages_on_conversation_id"
  add_index "messages", ["user_id"], name: "index_messages_on_user_id"

  create_table "project_comments", force: :cascade do |t|
    t.text     "body"
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.string   "country"
    t.string   "picture"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "user_id"
    t.datetime "expires_at"
    t.integer  "volunteers",              default: 0
    t.string   "state"
    t.text     "request_description"
    t.integer  "institution_id"
    t.string   "institution_name"
    t.string   "institution_logo"
    t.text     "institution_description"
    t.string   "institution_location"
  end

  create_table "task_comments", force: :cascade do |t|
    t.text     "body"
    t.integer  "user_id"
    t.integer  "task_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "title"
    t.text     "description"
    t.decimal  "budget"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.datetime "deadline"
    t.integer  "user_id"
    t.decimal  "current_fund",                  default: 0.0
    t.text     "condition_of_execution"
    t.string   "fileone"
    t.string   "filetwo"
    t.string   "filethree"
    t.string   "filefour"
    t.string   "filefive"
    t.string   "state"
    t.integer  "number_of_participants"
    t.integer  "target_number_of_participants"
    t.boolean  "assigned",                      default: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "name"
    t.integer  "role"
    t.string   "country"
    t.text     "description"
    t.string   "picture"
    t.string   "company"
    t.boolean  "admin",                  default: false
    t.boolean  "manager",                default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "wikis", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "project_id"
    t.string   "pictureone"
    t.string   "string"
    t.string   "picturetwo"
    t.string   "picturethree"
    t.string   "picturefour"
    t.string   "picturefive"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "user_id"
    t.string   "state"
  end

end
