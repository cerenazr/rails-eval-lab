# Phase 2: Evaluation Engine Core Schema & Services

We are implementing the robust `EvaluationEngine` architecture proposed by the external LLM. This includes the essential credit system, iteration logs, robust mathematical scoring, and the orchestrator service object running on top of our proven `eval/runner.rb` execution system.

## User Review Required

> [!CAUTION]
> The architectural design creates a `Challenge` model. Because our previous baseline script (`eval/runner.rb`) didn't use a database representation of the challenge, we will need to refactor the Scorer to integrate appropriately with the `Challenge` model. Verify that you approve of this architectural evolution.

> [!WARNING]
> The `strategy_note` is required for every run (minimum 20 characters) and is validated strictly at the database level. Students will be forced to describe their actions before submitting. E.g. "I used eager_load on posts and comments," etc.

## Proposed Changes

### Database Schema (Migrations)

We will introduce the new tables and constraints:
- **`20260329100000_add_credits_to_users.rb`**: Adds `credits` (default 100) and a `CHECK (credits >= 0)` constraint.
- **`20260329100001_create_challenges.rb`**: Creates `challenges` to store the known-bad baseline `baseline_queries` and `baseline_time_ms` so the `ScoreCalculator` can determine "reduction".
- **`20260329100002_create_run_logs.rb`**: Creates the append-only `run_logs` table tracking iteration behavior, strategies, and exact query/time outcomes.

### Models Layer

We will introduce the mapping between the new tables:
- **`app/models/challenge.rb`**: Model for evaluation challenges.
- **`app/models/run_log.rb`**: Model wrapping the atomic iterations with rigorous validations.
- **`app/models/user.rb`**: (Modification) Will be updated to wire `has_many :run_logs`.

### Service Object Layer (The Engine)

We form the transactional boundary around evaluation:
- **`app/services/evaluation_engine/execute_run.rb`**: Orchestrator (locks user row, calculates credits, fetches from scorer, calculates scores, persists run log).
- **`app/services/evaluation_engine/score_calculator.rb`**: Pure mathematical evaluation mapping reductions to a `0-100` scale.

### Scorer Adapter

- **`app/services/scorer.rb`**: Wrap our existing bash testing logic (from `eval/runner.rb` and `Benchmark`/`ActiveSupport::Notifications`) into a class interface `Scorer.run(challenge)` that dynamically executes the student code.

## Open Questions

> [!IMPORTANT]
> **Scorer Execution Integration:** `ExecuteRun` wraps `Scorer.run` in a database transaction (`user.lock!`). Since our evaluation currently runs in `< 5 seconds`, this single-transaction approach is fine for a classroom. If execution durations rise above 5s (due to heavy load or infinite looping student code), we will need to split the transactions. Are we fine starting with a single transaction?

> [!IMPORTANT]
> **Current Hardcoded Setup:** We only have one actual challenge code right now (`user_data_fetcher.rb`). Are you okay with me creating a database seed for this specific `Challenge` during execution?

## Verification Plan

### Automated Tests
- Build a stress-test integration spec (following the architectural prompt) invoking `EvaluationEngine::ExecuteRun.call` 3 sequential times.
- Ensure credits go from `100 -> 95 -> 90 -> 85`.
- Validate `stability_score` correctly reflects the reproducible runs.

### Manual Verification
- Output the current RunLogs to standard output via rails runner after simulating a mock run.
