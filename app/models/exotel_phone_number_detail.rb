# frozen_string_literal: true

class ExotelPhoneNumberDetail < ApplicationRecord
  belongs_to :patient_phone_number

  validates :patient_phone_number, uniqueness: true

  enum whitelist_status: {
    whitelist: "whitelist",
    neutral: "neutral",
    blacklist: "blacklist",
    requested: "requested"
  }, _prefix: true
end
