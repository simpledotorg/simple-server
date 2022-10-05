class Messaging::AlphaSms::Sms < Messaging::Channel
  def self.communication_type
    Communication.communication_types[:sms]
  end

  def self.get_message_statuses
    AlphaSmsDeliveryDetail.where("created_at > ?", 2.days.ago).in_progress.find_each do |detailable|
      AlphaSmsStatusJob.perform_async(detailable.request_id)
    end
  end

  def send_message(recipient_number:, message:, &with_communication_do)
    track_metrics do
      create_communication(
        recipient_number,
        message,
        send_sms(recipient_number, message)["data"]["request_id"],
        &with_communication_do
      )
    end
  end

  private

  def send_sms(recipient_number, message)
    Messaging::AlphaSms::Api.new.send_sms(
      recipient_number: recipient_number,
      message: message
    ).tap { |response| raise_api_errors(response) }
  end

  def raise_api_errors(response)
    error_code = response["error"]
    if error_code.present? && !error_code.zero?
      raise Messaging::AlphaSms::Error.new(response["msg"], error_code)
    end
  end

  def create_communication(recipient_number, message, request_id, &with_communication_do)
    ActiveRecord::Base.transaction do
      AlphaSmsDeliveryDetail.create_with_communication!(
        message: message,
        request_id: request_id,
        recipient_number: recipient_number
      ).tap do |communication|
        with_communication_do&.call(communication)
      end
    end
  end
end
