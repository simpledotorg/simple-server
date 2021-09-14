class ImoDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    error: "error"
    no_imo_account: "no_imo_account",
    not_subscribed: "not_subscribed",
    read: "read",
    sent: "sent"
  }
end