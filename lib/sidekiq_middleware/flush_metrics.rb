# Ensure that metrics are flushed to Datadog after the execution of jobs.
# See https://github.com/DataDog/dogstatsd-ruby/blob/master/examples/sidekiq_example.rb for more details.
module SidekiqMiddleware
  class FlushMetrics
    def call(_worker, _job, _queue)
      yield
    ensure
      Statsd.instance.flush(sync: true)
    end
  end
end
