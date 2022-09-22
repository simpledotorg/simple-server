class AlphaSmsDeliveryDetail < DeliveryDetail
  validates :request_id, presence: true
  validates :recipient_number, presence: true

  def unsuccessful?
    request_status != "Sent"
  end

  def successful?
    request_status == "Sent"
  end

  def in_progress?
    false
  end

  def self.create_with_communication!(request_id:, recipient_number:, message:)
    ActiveRecord::Base.transaction do
      delivery_detail = create!(
        request_id: request_id,
        recipient_number: recipient_number,
        message: message
      )

      Communication.create!(
        communication_type: Messaging::AlphaSms::Sms.communication_type,
        detailable: delivery_detail
      )
    end
  end
end
