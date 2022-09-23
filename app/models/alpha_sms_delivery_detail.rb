class AlphaSmsDeliveryDetail < DeliveryDetail
  SUCCESSFUL_REQUEST_STATUS = "Sent"
  validates :request_id, presence: true
  validates :recipient_number, presence: true

  scope :in_progress, -> { where(request_status: nil) }

  def unsuccessful?
    request_status != SUCCESSFUL_REQUEST_STATUS
  end

  def successful?
    request_status == SUCCESSFUL_REQUEST_STATUS
  end

  def in_progress?
    request_status.blank?
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
