class ImoAuthorization < ApplicationRecord
  belongs_to :patient
  validates :last_invitation_date, presence: true
  validates :status, presence: true

  enum status: {
    not_registered: "not_registered",
    registered: "registered",
    subscribed: "subscribed"
  }, _prefix: true
end