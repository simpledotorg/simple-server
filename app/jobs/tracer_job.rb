class TracerJob
  include Sidekiq::Worker
  sidekiq_options retry: false # job will be discarded if it fails

  def perform(submitted_at, raise_error)
    Statsd.instance.increment("tracer_job.count")
    if raise_error
      raise Admin::ErrorTracesController::Boom, "Error trace triggered via sidekiq!"
    end
    Rails.logger.info class: self.class.name,
      msg: "tracer job completed successfully, was submitted at #{submitted_at}",
      submitted_at: submitted_at
  end
end
