# frozen_string_literal: true

# Append-only record of every evaluation run.
# Equivalent to autoresearch's results.tsv — never edited, only appended.
#
# Design decisions:
# - No updated_at column: records are immutable after creation.
# - readonly? enforced at model level as second line of defense.
# - strategy_note is required: no "run first, think later" allowed.
class RunLog < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  # --- Validations ---
  validates :iteration_number, presence: true,
                               numericality: { only_integer: true, greater_than: 0 },
                               uniqueness: { scope: [:user_id, :challenge_id] }

  validates :strategy_note, presence: true,
                            length: { minimum: 20, message: "must explain your strategy (min 20 chars)" }

  validates :queries_count,    presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :execution_time_ms, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_score,      presence: true
  validates :credits_used,     presence: true, numericality: { only_integer: true, greater_than: 0 }

  # --- Append-only enforcement ---
  # DB has no updated_at column, but belt-and-suspenders:
  def readonly?
    persisted?
  end

  # --- Scopes ---
  scope :for_challenge, ->(challenge) { where(challenge: challenge) }
  scope :by_user,       ->(user)      { where(user: user) }
  scope :chronological, ->            { order(iteration_number: :asc) }
  scope :best_first,    ->            { order(total_score: :desc) }

  # --- Convenience ---
  def improved_over?(other)
    return true unless other
    total_score > other.total_score
  end

  def first_attempt?
    iteration_number == 1
  end
end
