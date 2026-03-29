# frozen_string_literal: true

class CreateRunLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :run_logs do |t|
      t.references :user,      null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true

      # --- Iteration identity ---
      t.integer :iteration_number, null: false

      # --- Student reasoning (the heart of learning) ---
      t.text :strategy_note, null: false

      # --- Raw metrics from Scorer ---
      t.integer :queries_count,    null: false
      t.decimal :execution_time_ms, null: false, precision: 10, scale: 2

      # --- Computed scores (stored for auditability, not recomputed) ---
      t.decimal :query_reduction_pct,  precision: 7, scale: 2  # can be negative
      t.decimal :time_reduction_pct,   precision: 7, scale: 2  # can be negative
      t.decimal :stability_score,      precision: 5, scale: 4  # 0.0000 - 1.0000
      t.decimal :total_score,          null: false, precision: 7, scale: 2

      t.integer :credits_used, null: false

      # Append-only: only created_at, no updated_at.
      t.datetime :created_at, null: false
    end

    # One iteration number per user per challenge. No gaps, no duplicates.
    add_index :run_logs,
              [:user_id, :challenge_id, :iteration_number],
              unique: true,
              name: "idx_run_logs_user_challenge_iteration"

    # Fast lookups for leaderboard and personal history.
    add_index :run_logs, [:challenge_id, :total_score], order: { total_score: :desc },
              name: "idx_run_logs_leaderboard"
  end
end
