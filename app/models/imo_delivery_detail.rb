class ImoDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    error: "error",
    no_imo_account: "no_imo_account",
    not_subscribed: "not_subscribed",
    read: "read",
    sent: "sent"
  }

  validates :result, presence: true
  validates :callee_phone_number, presence: true

  def unsuccessful?
    error? || no_imo_account? || not_subscribed?
  end

  def successful?
    read?
  end

  def in_progress?
    sent?
  end
end
