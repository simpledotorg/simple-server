class Messaging::Mobitel::Sms < Messaging::Channel
  API_SUCCESS_RESPONSE = 200

  def self.communication_type
    Communication.communication_types[:sms]
  end

  def send_message(recipient_number:, message:, &with_communication_do)
    track_metrics do
      send_sms(recipient_number, message)
      create_communication(
        recipient_number,
        message,
        &with_communication_do
      )
    end
  end

  private

  def send_sms(recipient_number, message)
    Messaging::Mobitel::Api.new.send_sms(
      recipient_number: recipient_number,
      message: message
    ).tap { |response| raise_api_errors(response) }
  end

  def raise_api_errors(body)
    code = body[:resultcode].to_i
    message = body[:response]
    unless code == API_SUCCESS_RESPONSE
      raise Messaging::Mobitel::Error.new("API failed with code: #{code} and message: #{message}", code)
    end
  end

  def create_communication(recipient_number, message, &with_communication_do)
    ActiveRecord::Base.transaction do
      MobitelDeliveryDetail.create_with_communication!(
        message: message,
        recipient_number: recipient_number
      ).tap do |communication|
        with_communication_do&.call(communication)
      end
    end
  end
end
