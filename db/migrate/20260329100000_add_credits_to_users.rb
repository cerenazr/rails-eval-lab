# frozen_string_literal: true

class AddCreditsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :credits, :integer, null: false, default: 100

    # Defense in depth: DB-level constraint prevents negative credits
    # even if application logic has a bug.
    add_check_constraint :users, "credits >= 0", name: "credits_non_negative"
  end
end
