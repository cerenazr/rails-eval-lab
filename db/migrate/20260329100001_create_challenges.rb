# frozen_string_literal: true

# NOTE: The scoring formula requires baseline metrics to calculate "reduction."
# Without a Challenge record holding baseline_queries and baseline_time_ms,
# the ScoreCalculator has nothing to compare against.
# This table is the "prepare.py" equivalent — the fixed evaluation context.

class CreateChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :challenges do |t|
      t.string  :slug,             null: false, index: { unique: true }
      t.string  :title,            null: false
      t.text    :description

      # The "known-bad" baseline that students optimize against.
      # These come from running the unoptimized code through the Scorer.
      t.integer :baseline_queries, null: false  # e.g., 147 SQL queries
      t.decimal :baseline_time_ms, null: false, precision: 10, scale: 2  # e.g., 842.50ms

      t.integer :credit_cost,      null: false, default: 5
      t.boolean :active,           null: false, default: true

      t.timestamps
    end
  end
end
