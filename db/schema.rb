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

ActiveRecord::Schema.define(version: 20160821215142) do

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
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "state"
    t.datetime "confirmed_at"
  end

  add_index "assignments", ["task_id", "user_id"], name: "index_assignments_on_task_id_and_user_id"

  create_table "cards", force: :cascade do |t|
    t.string   "title"
    t.string   "status"
    t.string   "list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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

  create_table "donations", force: :cascade do |t|
    t.decimal  "amount"
    t.integer  "task_id"
    t.integer  "user_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "paypal_email"
    t.text     "notification_params"
    t.string   "status"
    t.string   "transaction_id"
    t.datetime "completed_at"
    t.string   "PAYKEY"
  end

  create_table "generate_addresses", force: :cascade do |t|
    t.string   "address"
    t.boolean  "is_available"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "institution_users", force: :cascade do |t|
    t.integer  "institution_id"
    t.integer  "user_id"
    t.string   "position"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "institution_users", ["institution_id"], name: "index_institution_users_on_institution_id"
  add_index "institution_users", ["user_id"], name: "index_institution_users_on_user_id"

  create_table "institutions", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.string   "country"
    t.string   "city"
    t.string   "logo"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "url"
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

  create_table "notifications", force: :cascade do |t|
    t.string   "type"
    t.string   "summary"
    t.text     "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plans", force: :cascade do |t|
    t.text     "notes"
    t.text     "todos"
    t.string   "owner"
    t.string   "status"
    t.text     "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "profile_comments", force: :cascade do |t|
    t.integer  "commenter_id"
    t.integer  "receiver_id"
    t.text     "comment_text"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "profile_comments", ["commenter_id"], name: "index_profile_comments_on_commenter_id"
  add_index "profile_comments", ["receiver_id"], name: "index_profile_comments_on_receiver_id"

  create_table "proj_admins", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "state"
  end

  create_table "project_comments", force: :cascade do |t|
    t.text     "body"
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "project_edits", force: :cascade do |t|
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "aasm_state",  default: "pending"
    t.integer  "user_id"
    t.integer  "project_id"
    t.text     "description"
  end

  create_table "project_rates", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "rate",       default: 0
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "project_users", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
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
    t.string   "short_description"
    t.string   "institution_country"
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
    t.text     "proof_of_execution"
    t.text     "short_description"
    t.boolean  "marker",                        default: false
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.integer  "number_of_members"
    t.integer  "number_of_projects"
    t.text     "mission"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                            default: "",    null: false
    t.string   "encrypted_password",               default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                    default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "name"
    t.integer  "role"
    t.string   "country"
    t.text     "description"
    t.string   "picture"
    t.string   "company"
    t.boolean  "admin",                            default: false
    t.string   "first_link"
    t.string   "second_link"
    t.string   "third_link"
    t.string   "city"
    t.string   "fourth_link"
    t.string   "phone_number",           limit: 8
    t.integer  "institution_id"
    t.text     "bio"
    t.string   "facebook_url"
    t.string   "twitter_url"
    t.string   "linkedin_url"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["institution_id"], name: "index_users_on_institution_id"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "wallet_addresses", force: :cascade do |t|
    t.string   "sender_address"
    t.integer  "task_id"
    t.string   "wallet_addresses"
    t.string   "wallet_id"
    t.string   "receiver_address"
    t.float    "current_balance",  default: 0.0
    t.string   "pass_phrase"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "wallet_addresses", ["task_id"], name: "index_wallet_addresses_on_task_id"

  create_table "wallet_transactions", force: :cascade do |t|
    t.decimal  "amount"
    t.string   "user_wallet"
    t.string   "tx_hash"
    t.integer  "task_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "wallet_transactions", ["task_id"], name: "index_wallet_transactions_on_task_id"

  create_table "wikis", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "project_id"
    t.string   "pictureone"
    t.string   "picturetwo"
    t.string   "picturethree"
    t.string   "picturefour"
    t.string   "picturefive"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "user_id"
    t.string   "state"
  end

  create_table "work_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
