class PatientPhoneNumber < ApplicationRecord
  include Mergeable

  PHONE_TYPE = %w[mobile landline].freeze

  belongs_to :patient

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  has_one :exotel_phone_number_detail

  default_scope -> { order("device_created_at ASC") }

  def self.require_whitelisting
    relation = self.left_outer_joins(:exotel_phone_number_detail)

    relation.where(patient_phone_number: { dnd_status: true })
      .or(relation.where(exotel_phone_number_detail: {id: nil}))
  end 

  def can_be_called?
    !dnd_status ||
      (exotel_phone_number_detail.present? &&
        exotel_phone_number_detail.whitelist_status_whitelist? &&
        exotel_phone_number_detail.whitelist_status_valid_until > Time.now)
  end
end
