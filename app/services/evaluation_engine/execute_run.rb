# frozen_string_literal: true

module EvaluationEngine
  # The core orchestrator. Equivalent to Karpathy's experiment loop:
  #   1. Guard (credits check)
  #   2. Execute (Scorer.run)
  #   3. Evaluate (ScoreCalculator)
  #   4. Record (RunLog — the keep/revert decision is the student's job)
  #   5. Deduct (credits)
  #
  # All steps 1, 3–5 run inside a single transaction with a pessimistic
  # lock on the user row. Step 2 (Scorer.run) is also inside the
  # transaction for simplicity.
  #
  # ⚠️  SCALING NOTE: If Scorer.run becomes slow (>2s), split into:
  #     Transaction 1: lock + deduct credits (reserve)
  #     Outside:       Scorer.run
  #     Transaction 2: persist RunLog
  #     Compensating:  refund on failure
  #   For a classroom of 25 students with sub-second runs, single
  #   transaction is correct and simple.
  #
  # Usage:
  #   result = EvaluationEngine::ExecuteRun.call(
  #     user: current_user,
  #     challenge: challenge,
  #     strategy_note: "includes, eager_load kullanarak N+1 çözdüm"
  #   )
  #
  #   if result.success?
  #     result.run_log  # => RunLog instance
  #   else
  #     result.error    # => "Yetersiz kredi. 3 krediniz var, 5 gerekli."
  #   end
  class ExecuteRun
    Result = Struct.new(:run_log, :error, keyword_init: true) do
      def success? = error.nil?
      def failure? = !success?
    end

    def self.call(**args)
      new(**args).call
    end

    def initialize(user:, challenge:, strategy_note:)
      @user          = user
      @challenge     = challenge
      @strategy_note = strategy_note
    end

    def call
      ActiveRecord::Base.transaction do
        lock_user!
        guard_credits!

        metrics      = execute_scorer
        previous_run = fetch_previous_run
        scores       = calculate_scores(metrics, previous_run)
        run_log      = persist_run_log!(metrics, scores)

        deduct_credits!

        Result.new(run_log: run_log)
      end
    rescue InsufficientCredits => e
      Result.new(error: e.message)
    rescue ScorerFailure => e
      Result.new(error: "Scorer hatası: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      Result.new(error: "Kayıt hatası: #{e.record.errors.full_messages.join(', ')}")
    end

    private

    # --- Step 1: Lock & Guard ---

    def lock_user!
      # Pessimistic lock prevents race condition when student
      # double-clicks submit or has multiple tabs open.
      @user.lock!
    end

    def guard_credits!
      cost = @challenge.credit_cost
      if @user.credits < cost
        raise InsufficientCredits,
              "Yetersiz kredi. #{@user.credits} krediniz var, #{cost} gerekli."
      end
    end

    # --- Step 2: Execute ---

    def execute_scorer
      # Scorer is the external evaluation engine (the "prepare.py").
      # Contract: returns { queries: Integer, time: Float }
      result = Scorer.run(@challenge)

      unless result.is_a?(Hash) && result.key?(:queries) && result.key?(:time)
        raise ScorerFailure, "Beklenmeyen Scorer çıktısı: #{result.inspect}"
      end

      result
    rescue StandardError => e
      raise ScorerFailure, e.message unless e.is_a?(ScorerFailure)
      raise
    end

    # --- Step 3: Evaluate ---

    def fetch_previous_run
      RunLog.where(user: @user, challenge: @challenge)
            .order(iteration_number: :desc)
            .first
    end

    def calculate_scores(metrics, previous_run)
      ScoreCalculator.new(
        challenge:    @challenge,
        metrics:      metrics,
        previous_run: previous_run
      ).call
    end

    # --- Step 4: Record ---

    def persist_run_log!(metrics, scores)
      RunLog.create!(
        user:                @user,
        challenge:           @challenge,
        iteration_number:    next_iteration_number,
        strategy_note:       @strategy_note,
        queries_count:       metrics[:queries],
        execution_time_ms:   metrics[:time],
        query_reduction_pct: scores.query_reduction_pct,
        time_reduction_pct:  scores.time_reduction_pct,
        stability_score:     scores.stability_score,
        total_score:         scores.total_score,
        credits_used:        @challenge.credit_cost
      )
    end

    def next_iteration_number
      current_max = RunLog.where(user: @user, challenge: @challenge)
                         .maximum(:iteration_number)
      (current_max || 0) + 1
    end

    # --- Step 5: Deduct ---

    def deduct_credits!
      new_balance = @user.credits - @challenge.credit_cost

      # This should never fire due to guard_credits!, but defense in depth.
      raise InsufficientCredits, "Kredi bakiyesi negatife düşemez" if new_balance.negative?

      @user.update_column(:credits, new_balance)
    end

    # --- Custom Exceptions ---

    class InsufficientCredits < StandardError; end
    class ScorerFailure < StandardError; end
  end
end
