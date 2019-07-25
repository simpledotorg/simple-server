class PatientPhoneNumber < ApplicationRecord
  include Mergeable

  PHONE_TYPE = %w[mobile landline].freeze

  belongs_to :patient

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  has_one :exotel_phone_number_detail

  default_scope -> { order("device_created_at ASC") }

  WHITELIST_PERIOD = 6.months

  def self.require_whitelisting
    self.unscoped
      .left_outer_joins(:exotel_phone_number_detail)
      .where(patient_phone_numbers: { dnd_status: true })
      .where(%Q(
        (exotel_phone_number_details.whitelist_status is null) OR
        (exotel_phone_number_details.whitelist_status = 'neutral') OR
        (exotel_phone_number_details.whitelist_status = 'requested' AND exotel_phone_number_details.whitelist_requested_at <= '#{WHITELIST_PERIOD.ago}') OR
        (exotel_phone_number_details.whitelist_status = 'whitelist' AND exotel_phone_number_details.whitelist_status_valid_until <= '#{Time.now}'))
      )
  end

  def update_exotel_phone_number_detail(attributes)
    transaction do
      self.update!(attributes.slice(:dnd_status, :phone_type))
      if self.exotel_phone_number_detail.present?
        self.exotel_phone_number_detail.update!(attributes.slice(:whitelist_status, :whitelist_status_valid_until))
      else
        ExotelPhoneNumberDetail.create!(
          { patient_phone_number_id: self.id }
            .merge(attributes.slice(:whitelist_status, :whitelist_status_valid_until)))
      end
    end
  end

  def update_whitelist_requested_at(time)
    unless exotel_phone_number_detail.present?
      return ExotelPhoneNumberDetail.create(
        patient_phone_number: self,
        whitelist_status: ExotelPhoneNumberDetail.whitelist_statuses[:requested],
        whitelist_requested_at: time
      )
    end

    exotel_phone_number_detail.update(whitelist_requested_at: time)
  end
end
