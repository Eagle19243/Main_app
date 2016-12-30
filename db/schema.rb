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

ActiveRecord::Schema.define(version: 20161227194556) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "action"
    t.integer  "targetable_id"
    t.string   "targetable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "activities", ["targetable_type", "targetable_id"], name: "index_activities_on_targetable_type_and_targetable_id", using: :btree
  add_index "activities", ["user_id"], name: "index_activities_on_user_id", using: :btree

  create_table "admin_invitations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "status",     default: 0
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "sender_id"
  end

  add_index "admin_invitations", ["project_id"], name: "index_admin_invitations_on_project_id", using: :btree
  add_index "admin_invitations", ["user_id"], name: "index_admin_invitations_on_user_id", using: :btree

  create_table "admin_requests", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "status",     default: 0
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "admin_requests", ["project_id"], name: "index_admin_requests_on_project_id", using: :btree
  add_index "admin_requests", ["user_id"], name: "index_admin_requests_on_user_id", using: :btree

  create_table "apply_requests", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "request_type"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.datetime "accepted_at"
    t.datetime "rejected_at"
  end

  create_table "assignments", force: :cascade do |t|
    t.integer  "task_id"
    t.integer  "user_id"
    t.boolean  "free"
    t.datetime "deadline"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "state"
    t.datetime "confirmed_at"
    t.boolean  "invitation_sent"
    t.integer  "project_id"
  end

  add_index "assignments", ["task_id", "user_id"], name: "index_assignments_on_task_id_and_user_id", using: :btree

  create_table "cards", force: :cascade do |t|
    t.string   "title"
    t.string   "status"
    t.string   "list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "change_leader_invitations", force: :cascade do |t|
    t.string   "new_leader"
    t.datetime "sent_at"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.string   "project_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.string   "chat_rooms"
    t.string   "room_id"
    t.string   "string"
    t.integer  "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "chat_rooms", ["project_id"], name: "index_chat_rooms_on_project_id", using: :btree

  create_table "chatrooms", force: :cascade do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "friend_id"
  end

  add_index "chatrooms", ["project_id"], name: "index_chatrooms_on_project_id", using: :btree
  add_index "chatrooms", ["user_id"], name: "index_chatrooms_on_user_id", using: :btree

  create_table "conversations", force: :cascade do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "discussions", force: :cascade do |t|
    t.integer  "discussable_id"
    t.string   "discussable_type"
    t.integer  "user_id"
    t.string   "field_name"
    t.text     "context"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "discussions", ["discussable_type", "discussable_id"], name: "index_discussions_on_discussable_type_and_discussable_id", using: :btree

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
    t.integer  "project_id"
  end

  add_index "do_requests", ["task_id", "user_id"], name: "index_do_requests_on_task_id_and_user_id", using: :btree

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
    t.string   "sender_address"
    t.boolean  "is_available"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "wallet_id"
    t.string   "receiver_address"
    t.string   "pass_phrase"
  end

  create_table "group_messages", force: :cascade do |t|
    t.string   "message"
    t.integer  "user_id"
    t.integer  "chatroom_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "attachment"
  end

  add_index "group_messages", ["chatroom_id"], name: "index_group_messages_on_chatroom_id", using: :btree
  add_index "group_messages", ["user_id"], name: "index_group_messages_on_user_id", using: :btree

  create_table "groupmembers", force: :cascade do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "chatroom_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "groupmembers", ["chatroom_id"], name: "index_groupmembers_on_chatroom_id", using: :btree
  add_index "groupmembers", ["user_id"], name: "index_groupmembers_on_user_id", using: :btree

  create_table "institution_users", force: :cascade do |t|
    t.integer  "institution_id"
    t.integer  "user_id"
    t.string   "position"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "institution_users", ["institution_id"], name: "index_institution_users_on_institution_id", using: :btree
  add_index "institution_users", ["user_id"], name: "index_institution_users_on_user_id", using: :btree

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
    t.string   "image"
  end

  add_index "messages", ["conversation_id"], name: "index_messages_on_conversation_id", using: :btree
  add_index "messages", ["user_id"], name: "index_messages_on_user_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "user_id"
    t.integer  "action",            default: 0
    t.integer  "source_model_id"
    t.string   "source_model_type"
    t.integer  "origin_user_id"
    t.boolean  "read",              default: false
  end

  add_index "notifications", ["source_model_type", "source_model_id"], name: "index_notifications_on_source_model_type_and_source_model_id", using: :btree
  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

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

  add_index "profile_comments", ["commenter_id"], name: "index_profile_comments_on_commenter_id", using: :btree
  add_index "profile_comments", ["receiver_id"], name: "index_profile_comments_on_receiver_id", using: :btree

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
    t.datetime "deleted_at"
  end

  add_index "project_comments", ["deleted_at"], name: "index_project_comments_on_deleted_at", using: :btree

  create_table "project_edits", force: :cascade do |t|
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "aasm_state",  default: "pending"
    t.integer  "user_id"
    t.integer  "project_id"
    t.text     "description"
    t.datetime "deleted_at"
  end

  add_index "project_edits", ["deleted_at"], name: "index_project_edits_on_deleted_at", using: :btree

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
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "user_id"
    t.datetime "expires_at"
    t.integer  "volunteers",          default: 0
    t.string   "state"
    t.text     "request_description"
    t.string   "short_description"
    t.string   "video_id"
    t.datetime "deleted_at"
    t.string   "wiki_page_name"
  end

  add_index "projects", ["deleted_at"], name: "index_projects_on_deleted_at", using: :btree

  create_table "section_details", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "parent_id"
    t.integer  "order"
    t.string   "title",      default: ""
    t.text     "context",    default: ""
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "section_details", ["project_id"], name: "index_section_details_on_project_id", using: :btree

  create_table "task_attachments", force: :cascade do |t|
    t.integer  "task_id"
    t.string   "attachment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
  end

  create_table "task_comments", force: :cascade do |t|
    t.text     "body"
    t.integer  "user_id"
    t.integer  "task_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "task_members", force: :cascade do |t|
    t.integer  "team_membership_id"
    t.integer  "task_id"
    t.datetime "created_at"
  end

  add_index "task_members", ["task_id"], name: "index_task_members_on_task_id", using: :btree
  add_index "task_members", ["team_membership_id"], name: "index_task_members_on_team_membership_id", using: :btree

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
    t.integer  "number_of_participants",        default: 0
    t.integer  "target_number_of_participants", default: 0
    t.boolean  "assigned",                      default: false
    t.text     "proof_of_execution"
    t.text     "short_description"
    t.boolean  "marker",                        default: false
    t.datetime "deleted_at"
  end

  add_index "tasks", ["deleted_at"], name: "index_tasks_on_deleted_at", using: :btree

  create_table "team_memberships", force: :cascade do |t|
    t.integer  "team_id",                    null: false
    t.integer  "team_member_id",             null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "role",           default: 0
  end

  add_index "team_memberships", ["team_id", "team_member_id"], name: "index_team_memberships_on_team_id_and_team_member_id", unique: true, using: :btree
  add_index "team_memberships", ["team_id"], name: "index_team_memberships_on_team_id", using: :btree
  add_index "team_memberships", ["team_member_id"], name: "index_team_memberships_on_team_member_id", using: :btree

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "project_id"
  end

  add_index "teams", ["project_id"], name: "index_teams_on_project_id", using: :btree

  create_table "user_wallet_addresses", force: :cascade do |t|
    t.string   "sender_address"
    t.string   "wallet_id"
    t.string   "receiver_address"
    t.float    "current_balance"
    t.string   "pass_phrase"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "user_keys"
    t.string   "backup_keys"
  end

  add_index "user_wallet_addresses", ["user_id"], name: "index_user_wallet_addresses_on_user_id", using: :btree

  create_table "user_wallet_transactions", force: :cascade do |t|
    t.decimal  "amount"
    t.string   "user_wallet"
    t.string   "tx_hash"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
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
    t.text     "bio"
    t.string   "facebook_url"
    t.string   "twitter_url"
    t.string   "linkedin_url"
    t.string   "chat_token"
    t.string   "guid"
    t.string   "provider"
    t.string   "uid"
    t.integer  "test_id"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "username"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

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

  add_index "wallet_addresses", ["task_id"], name: "index_wallet_addresses_on_task_id", using: :btree

  create_table "wallet_transactions", force: :cascade do |t|
    t.decimal  "amount"
    t.string   "user_wallet"
    t.string   "tx_hash"
    t.integer  "task_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "wallet_transactions", ["task_id"], name: "index_wallet_transactions_on_task_id", using: :btree

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
    t.datetime "deleted_at"
  end

  add_index "wikis", ["deleted_at"], name: "index_wikis_on_deleted_at", using: :btree

  create_table "work_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "admin_invitations", "projects"
  add_foreign_key "admin_invitations", "users"
  add_foreign_key "admin_invitations", "users", column: "sender_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "admin_requests", "projects"
  add_foreign_key "admin_requests", "users"
  add_foreign_key "chat_rooms", "projects"
  add_foreign_key "group_messages", "chatrooms"
  add_foreign_key "group_messages", "users"
  add_foreign_key "groupmembers", "chatrooms"
  add_foreign_key "groupmembers", "users"
  add_foreign_key "institution_users", "institutions"
  add_foreign_key "institution_users", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "origin_user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "section_details", "projects"
  add_foreign_key "task_members", "tasks"
  add_foreign_key "task_members", "team_memberships"
  add_foreign_key "user_wallet_addresses", "users"
  add_foreign_key "wallet_addresses", "tasks"
  add_foreign_key "wallet_transactions", "tasks"
end
