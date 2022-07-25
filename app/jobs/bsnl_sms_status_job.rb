class BsnlSmsStatusJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  BSNL_TIME_ZONE = "Asia/Kolkata"

  sidekiq_options queue: :default
  sidekiq_options retry: 3

  sidekiq_throttle(
    threshold: {limit: 250, period: 1.minute}
  )

  def perform(message_id)
    response = Messaging::Bsnl::Api.new.get_message_status_report(message_id)
    raise_api_errors(message_id, response)

    detailable = BsnlDeliveryDetail.find_by!(message_id: message_id)
    detailable.message_status = response["Message_Status"] if response["Message_Status"]
    detailable.message = response["Message"] if response["Message"]
    detailable.result = response["Message_Status_Description"] if response["Message_Status_Description"]
    detailable.delivered_on = parse_timestamp(response["Delivery_Success_Time"]) if response["Delivery_Success_Time"]
    detailable.save!

    log(response)
  end

  private

  def log(response)
    Rails.logger.info(
      {
        job: "bsnl_sms_status",
        message_id: response["Message_Id"],
        content_template_id: response["Content_Template_Id"],
        error: response["Error"],
        sms_count: response["SMS_Count"],
        dlr_error_code: response["DLR_Error_Code"]
      }
    )
  end

  def raise_api_errors(message_id, response)
    error = response["Error"]
    if error.present?
      raise Messaging::Bsnl::FetchStatusError.new("Error fetching message status for #{message_id}: #{error}")
    end
  end

  def parse_timestamp(timestamp)
    ActiveSupport::TimeZone.new(BSNL_TIME_ZONE).strptime(timestamp, "%d-%m-%Y %H:%M:%S %p")
  end
end
