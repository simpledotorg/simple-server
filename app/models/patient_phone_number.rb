class PatientPhoneNumber < ApplicationRecord
  include Mergeable

  PHONE_TYPE = %w[mobile landline].freeze

  belongs_to :patient

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  validates :dnd_status, inclusion: [true, false]
  has_one :exotel_phone_number_detail

  default_scope -> { order("device_created_at ASC") }

  def self.require_whitelisting
    self.unscoped
      left_outer_joins(:exotel_phone_number_detail)
      .where(patient_phone_numbers: { dnd_status: true })
      .where(%Q(
        (exotel_phone_number_details.whitelist_status is null) OR
        (exotel_phone_number_details.whitelist_status = 'neutral') OR
        (exotel_phone_number_details.whitelist_status = 'requested' AND exotel_phone_number_details.whitelist_requested_at <= '#{6.months.ago}') OR
        (exotel_phone_number_details.whitelist_status = 'whitelist' AND exotel_phone_number_details.whitelist_status_valid_until <= '#{Time.now}'))
      ).order('exotel_phone_number_details.whitelist_requested_at ASC NULLS FIRST, patient_phone_numbers.device_created_at')
  end

  def can_be_called?
    !dnd_status ||
      (exotel_phone_number_detail.present? &&
        exotel_phone_number_detail.whitelist_status_whitelist? &&
        exotel_phone_number_detail.whitelist_status_valid_until > Time.now)
  end
end
