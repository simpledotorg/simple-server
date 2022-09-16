class AlphaSmsDeliveryDetail < DeliveryDetail
  validates :request_id, presence: true
  validates :recipient_number, presence: true
  # creation API: msg: "Request successfully submited"
  # status API: msg: "Success"
  #             data: request_status: "Complete"

  def unsuccessful?
  #  Fill this in based on request_status
  end

  def successful?
    #  Fill this in based on request_status
  end

  def in_progress?
    #  Fill this in based on request_status
  end

  def self.create_with_communication!(request_id:, recipient_number:, message:)
    ActiveRecord::Base.transaction do
      delivery_detail = create!(
        message_id: request_id,
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
