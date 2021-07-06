Sentry.init do |config|
  config.async = ->(event, hint) do
    Sentry::SendEventJob.perform_later(event, hint)
  end

  config.traces_sampler = lambda do |sampling_context|
    transaction_context = sampling_context[:transaction_context]
    op = transaction_context[:op]

    case op
    when /request/ # web requests
      0.20
    when /sidekiq/i # background jobs
      0.001
    else
      0.0
    end
  end
end
