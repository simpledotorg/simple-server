class MobitelDeliveryDetail < DeliveryDetail
  # Mobitel APIs are not capable of providing delivery details.
  # Hence we consider all the requests that passed the API validation as successful
  def successful?
    true
  end

  def unsuccessful?
    false
  end

  def in_progress?
    false
  end

  def self.create_with_communication!(message:, recipient_number:)
    ActiveRecord::Base.transaction do
      delivery_detail = create!(
        message: message,
        recipient_number: recipient_number
      )

      Communication.create!(
        communication_type: Messaging::Mobitel::Sms.communication_type,
        detailable: delivery_detail
      )
    end
  end
end
