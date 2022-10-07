class AlphaSmsStatusJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :default
  sidekiq_options retry: 3

  sidekiq_throttle(
    threshold: {limit: 250, period: 1.minute}
  )

  def perform(request_id)
    detailable = AlphaSmsDeliveryDetail.find_by!(request_id: request_id)
    response = Messaging::AlphaSms::Api.new.get_message_status_report(request_id)
    raise_api_errors(request_id, response)
    delivery_status_data = response.dig("data", "recipients").first["status"]

    detailable.request_status = delivery_status_data if delivery_status_data
    detailable.save!
  end

  def raise_api_errors(request_id, response)
    error = response["error"]
    unless error.zero?
      raise Messaging::AlphaSms::Error.new("Error fetching message status for #{request_id}: #{error}")
    end
  end
end
