class RecordCounterJob
  include Sidekiq::Worker

  def perform
    RecordCounter.call
  end
end
