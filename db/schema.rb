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

ActiveRecord::Schema[8.1].define(version: 2026_06_16_220515) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "days", force: :cascade do |t|
    t.date "completed_date"
    t.integer "completed_vertical_distance", default: 0
    t.datetime "created_at", null: false
    t.integer "planned_vertical_distance", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "strava_activity_id"
    t.datetime "updated_at", null: false
    t.bigint "week_id", null: false
    t.index ["week_id"], name: "index_days_on_week_id"
  end

  create_table "plans", force: :cascade do |t|
    t.integer "baseline_duration", default: 0, null: false
    t.integer "baseline_vertical_distance", default: 0, null: false
    t.date "completed_date"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.boolean "flexible_end_date", default: false, null: false
    t.integer "goal_duration", default: 0
    t.integer "goal_vertical_distance", default: 0, null: false
    t.integer "recovery_pattern", default: 0, null: false
    t.date "start_date"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "vertical_build_percentage", default: 10, null: false
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "auth_token"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["auth_token"], name: "index_sessions_on_auth_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "weeks", force: :cascade do |t|
    t.string "category"
    t.integer "completed_duration", default: 0, null: false
    t.integer "completed_vertical_distance", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.boolean "is_recovery", default: false, null: false
    t.bigint "plan_id", null: false
    t.integer "planned_duration", default: 0, null: false
    t.integer "planned_vertical_distance", default: 0, null: false
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "week_number", null: false
    t.index ["plan_id", "week_number"], name: "index_weeks_on_plan_id_and_week_number", unique: true
    t.index ["plan_id"], name: "index_weeks_on_plan_id"
  end

  add_foreign_key "days", "weeks"
  add_foreign_key "plans", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "weeks", "plans"
end
