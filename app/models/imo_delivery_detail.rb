class ImoDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    error: "error",
    no_imo_account: "no_imo_account",
    not_subscribed: "not_subscribed",
    read: "read",
    sent: "sent"
  }

  after_create :update_authorization, if: proc {|detail| detail.result.in? [:not_subscribed, :no_imo_account] }

  private

  def update_authorization
    patient = communication.notification.patient
    patient.imo_authorization.update!(status: result)
  end
end