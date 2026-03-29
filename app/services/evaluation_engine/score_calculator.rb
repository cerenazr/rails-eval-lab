# frozen_string_literal: true

module EvaluationEngine
  # Pure calculation object. No database writes, no side effects.
  # Takes raw metrics + baseline, returns all score components.
  #
  # Scoring formula (0–100 scale):
  #   Query Reduction  × 0.60  (max 60 pts)
  #   Time Reduction   × 0.30  (max 30 pts)
  #   Stability Bonus  × 10    (max 10 pts)
  #
  # Reductions can be negative (student made it worse).
  # total_score is floored at 0.0 — no negative totals.
  #
  # Stability measures reproducibility: how close are this run's
  # metrics to the previous run? First attempt always gets 0.
  class ScoreCalculator
    Result = Data.define(
      :query_reduction_pct,
      :time_reduction_pct,
      :stability_score,
      :total_score
    )

    QUERY_WEIGHT    = 0.60
    TIME_WEIGHT     = 0.30
    STABILITY_SCALE = 10.0

    def initialize(challenge:, metrics:, previous_run: nil)
      @challenge    = challenge
      @queries      = metrics[:queries]
      @time         = metrics[:time]
      @previous_run = previous_run
    end

    def call
      qr = query_reduction_pct
      tr = time_reduction_pct
      ss = stability_score

      total = (qr * QUERY_WEIGHT) + (tr * TIME_WEIGHT) + (ss * STABILITY_SCALE)

      Result.new(
        query_reduction_pct: qr.round(2),
        time_reduction_pct:  tr.round(2),
        stability_score:     ss.round(4),
        total_score:         [total, 0.0].max.round(2)
      )
    end

    private

    def query_reduction_pct
      return 0.0 if @challenge.baseline_queries.zero?
      ((@challenge.baseline_queries - @queries).to_f / @challenge.baseline_queries) * 100
    end

    def time_reduction_pct
      return 0.0 if @challenge.baseline_time_ms.zero?
      ((@challenge.baseline_time_ms - @time).to_f / @challenge.baseline_time_ms) * 100
    end

    # Stability: inverse of normalized metric delta from previous run.
    # First run = 0.0 (no comparison possible).
    # Identical to previous = 1.0 (perfectly reproducible).
    def stability_score
      return 0.0 unless @previous_run

      query_delta = (@queries - @previous_run.queries_count).abs.to_f
      time_delta  = (@time - @previous_run.execution_time_ms.to_f).abs

      # Normalize deltas relative to baseline so different challenges are comparable.
      norm_q = query_delta / [@challenge.baseline_queries, 1].max
      norm_t = time_delta  / [@challenge.baseline_time_ms.to_f, 1.0].max

      # Decay function: 1/(1+delta). Fast drop for large deltas, smooth near 0.
      q_stability = 1.0 / (1.0 + norm_q)
      t_stability = 1.0 / (1.0 + norm_t)

      (q_stability + t_stability) / 2.0
    end
  end
end
