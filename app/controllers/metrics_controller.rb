class MetricsController < ApplicationController
  def index
    result = SendgridService.new.check_credits

    if result[:error]
      render plain: "Error fetching metrics: #{result[:error]}", status: :unprocessable_entity
    else
      metrics = {
        sendgrid_total_emails: result[:total],
        sendgrid_emails_remaining_count: result[:remain],
        sendgrid_email_used_count: result[:used],
        sendgrid_plan_limit_expire: result[:plan_completion_status],
        sendgrid_email_limit_exceeded_by_threshold_limit: result[:exceeded_limit_status],
        sendgrid_http_return_code: result[:http_return_code],
        sendgrid_http_response_time: result[:http_response_time].round(2)
      }

      render plain: metrics_to_plain(metrics)
    end
  end

  private

  def metrics_to_plain(metrics)
    metrics.map do |key, value|
      <<~METRIC
        # HELP #{key} #{key.to_s.humanize}
        # TYPE #{key} gauge
        #{key} #{value}
      METRIC
    end.join("\n")
  end
end
