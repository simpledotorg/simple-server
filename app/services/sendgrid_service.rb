class SendgridService
  THRESHOLD = 45_000

  def check_credits
    start_time = Time.now
    Rails.logger.info("SendGrid balance check started...")

    sg = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
    response = sg.client.user.credits.get

    response_time = Time.now - start_time
    http_return_code = response.status_code.to_i

    return handle_error(response) unless http_return_code == 200

    data = JSON.parse(response.body)
    metrics = parse_metrics(data).merge(
      http_return_code: http_return_code,
      http_response_time: response_time
    )

    Rails.logger.info("SendGrid balance check completed.")
    metrics
  rescue => e
    Rails.logger.error("Error during SendGrid balance check: #{e.message}")
    {error: e.message}
  end

  private

  def parse_metrics(data)
    total = data["total"]
    remain = data["remain"]
    used = data["used"]
    plan_reset_date = Date.parse(data["next_reset"]) + 1
    time_until_expiration_seconds = [(plan_reset_date - Date.today).to_i * 24 * 60 * 60, 0].max
    {
      total: total,
      remain: remain,
      used: used,
      time_until_expiration_seconds: time_until_expiration_seconds
    }
  end

  def handle_error(response)
    Rails.logger.error("Failed to fetch SendGrid credits: #{response.body}")
    {error: response.body}
  end
end
