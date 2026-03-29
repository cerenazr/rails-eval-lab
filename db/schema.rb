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

ActiveRecord::Schema[8.0].define(version: 2026_03_29_172017) do
  create_table "challenges", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "baseline_queries", null: false
    t.decimal "baseline_time_ms", precision: 10, scale: 2, null: false
    t.integer "credit_cost", default: 5, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_challenges_on_slug", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.integer "post_id", null: false
    t.string "author_name"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.text "body"
    t.boolean "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "bio"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "run_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "challenge_id", null: false
    t.integer "iteration_number", null: false
    t.text "strategy_note", null: false
    t.integer "queries_count", null: false
    t.decimal "execution_time_ms", precision: 10, scale: 2, null: false
    t.decimal "query_reduction_pct", precision: 7, scale: 2
    t.decimal "time_reduction_pct", precision: 7, scale: 2
    t.decimal "stability_score", precision: 5, scale: 4
    t.decimal "total_score", precision: 7, scale: 2, null: false
    t.integer "credits_used", null: false
    t.datetime "created_at", null: false
    t.index ["challenge_id", "total_score"], name: "idx_run_logs_leaderboard", order: { total_score: :desc }
    t.index ["challenge_id"], name: "index_run_logs_on_challenge_id"
    t.index ["user_id", "challenge_id", "iteration_number"], name: "idx_run_logs_user_challenge_iteration", unique: true
    t.index ["user_id"], name: "index_run_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active"
    t.integer "credits", default: 100, null: false
    t.check_constraint "credits >= 0", name: "credits_non_negative"
  end

  add_foreign_key "comments", "posts"
  add_foreign_key "posts", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "run_logs", "challenges"
  add_foreign_key "run_logs", "users"
end
