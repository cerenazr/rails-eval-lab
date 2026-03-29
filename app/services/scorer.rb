# frozen_string_literal: true

require 'benchmark'

class Scorer
  def self.run(challenge)
    query_count = 0

    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      # Ignore schema and transaction queries
      unless event.payload[:name] == 'SCHEMA' || ['BEGIN', 'COMMIT'].include?(event.payload[:sql])
        query_count += 1
      end
    end

    time = Benchmark.realtime do
      UserDataFetcher.new.call
    end

    ActiveSupport::Notifications.unsubscribe(subscriber)

    {
      queries: query_count,
      time: time * 1000 # Convert to milliseconds for the scale defined in the schema
    }
  rescue StandardError => e
    # Re-raise standard errors to be caught gracefully by ExecuteRun
    raise "Scorer runtime error: #{e.message}"
  end
end
