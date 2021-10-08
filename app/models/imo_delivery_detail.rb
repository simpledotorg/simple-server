class ImoDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    no_imo_account: "no_imo_account",
    not_subscribed: "not_subscribed",
    read: "read",
    sent: "sent"
  }

  validates :result, presence: true
  validates :callee_phone_number, presence: true

  def unsuccessful?
    no_imo_account? || not_subscribed?
  end

  def successful?
    read?
  end

  def in_progress?
    sent?
  end

  def unsubscribed_or_missing?
    no_imo_account? || not_subscribed?
  end
end
