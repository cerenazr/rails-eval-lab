# frozen_string_literal: true

# The fixed evaluation context — equivalent to Karpathy's prepare.py.
# Instructors create these; students never modify them.
#
# Example seed:
#   Challenge.create!(
#     slug: "n_plus_one_dashboard",
#     title: "Dashboard N+1 Katliamı",
#     description: "Kullanıcı dashboard'u 147 SQL sorgusu çalıştırıyor. Düzelt.",
#     baseline_queries: 147,
#     baseline_time_ms: 842.50,
#     credit_cost: 5
#   )
class Challenge < ApplicationRecord
  has_many :run_logs, dependent: :restrict_with_error

  validates :slug,  presence: true, uniqueness: true,
                    format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase, digits, underscores" }
  validates :title, presence: true

  validates :baseline_queries, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :baseline_time_ms, presence: true, numericality: { greater_than: 0 }
  validates :credit_cost,      presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :active, -> { where(active: true) }
end
