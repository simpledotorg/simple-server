class ImoAuthorization < ApplicationRecord
  belongs_to :patient
  validates :last_invited_at, presence: true
  validates :status, presence: true

  enum status: {
    invited: "invited",
    no_imo_account: "no_imo_account",
    subscribed: "subscribed",
    not_subscribed: "not_subscribed"
  }, _prefix: true
end
