Sentry.init do |config|
  config.async = lambda do |event, hint|
    Sentry::SendEventJob.perform_later(event, hint)
  end

  config.traces_sampler = lambda do |sampling_context|
    transaction_context = sampling_context[:transaction_context]
    transaction_name = transaction_context[:name]
    op = transaction_context[:op]

    case op
    when /request/ # web requests
      case transaction_name
      when /ping/
        0.0
      else
        0.10
      end
    when /sidekiq/i # background jobs
      0.005
    else
      0.0
    end
  end
end
