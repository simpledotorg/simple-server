# frozen_string_literal: true

class RecordCounterJob
  include Sidekiq::Worker

  def perform
    RecordCounter.call
  end
end
