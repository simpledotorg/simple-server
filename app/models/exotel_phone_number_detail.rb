class ExotelPhoneNumberDetail < ApplicationRecord

  belongs_to :patient_phone_number

  validates :whitelist_status, presence: true

  enum whitelist_status: {
    whitelist: 'whitelist',
    neutral: 'neutral',
    blacklist: 'blacklist'
  }, _prefix: true
end
