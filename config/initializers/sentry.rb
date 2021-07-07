Sentry.init do |config|
  config.async = lambda do |event, hint|
    Sentry::SendEventJob.perform_later(event, hint)
  end

  config.traces_sampler = lambda do |sampling_context|
    transaction_context = sampling_context[:transaction_context]
    op = transaction_context[:op]

    case op
    when /request/ # web requests
      0.20
    when /sidekiq/i # background jobs
      0.01
    else
      0.0
    end
  end
end
