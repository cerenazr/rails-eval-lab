require 'rails_helper'

RSpec.describe EvaluationEngine::ExecuteRun do
  let!(:challenge) { Challenge.create!(slug: 'test', title: 'Test', baseline_queries: 100, baseline_time_ms: 50.0, credit_cost: 5) }
  let!(:user) { User.create!(name: 'Test', email: 'test@example.com', credits: 100) }

  before do
    # Mock the Scorer to return consistent values
    allow(Scorer).to receive(:run).and_return({ queries: 50, time: 25.0 })
  end

  it 'handles 3 sequential runs properly reducing credits and tracking stability' do
    # Run 1
    result1 = described_class.call(user: user, challenge: challenge, strategy_note: 'I tried caching. This should be longer than 20 chars.')
    expect(result1.success?).to be_truthy
    expect(user.reload.credits).to eq(95)
    expect(result1.run_log.iteration_number).to eq(1)
    expect(result1.run_log.stability_score.to_f).to eq(0.0)

    # Run 2
    result2 = described_class.call(user: user, challenge: challenge, strategy_note: 'I used eager loading to fix N+1.')
    expect(result2.success?).to be_truthy
    expect(user.reload.credits).to eq(90)
    expect(result2.run_log.iteration_number).to eq(2)
    # Identical metrics to run 1 means perfect stability = 1.0
    expect(result2.run_log.stability_score.to_f).to eq(1.0)

    # Run 3
    result3 = described_class.call(user: user, challenge: challenge, strategy_note: 'Just running again because I can.')
    expect(result3.success?).to be_truthy
    expect(user.reload.credits).to eq(85)
    expect(result3.run_log.iteration_number).to eq(3)
    expect(result3.run_log.stability_score.to_f).to eq(1.0)
  end

  it 'prevents running out of credits' do
    user.update_column(:credits, 3) # Less than the cost of 5

    result = described_class.call(user: user, challenge: challenge, strategy_note: 'This will fail due to credits.')
    expect(result.success?).to be_falsey
    expect(result.error).to match(/Yetersiz kredi/)
    expect(user.reload.credits).to eq(3) # Not deducted
  end
end
