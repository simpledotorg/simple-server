class PatientPhoneNumber < ApplicationRecord
  include Mergeable
  include PhoneNumberLocalization

  alias_attribute :phone_number, :number

  enum phone_type: {
    mobile: "mobile",
    landline: "landline",
    invalid: "invalid"
  }, _prefix: true

  belongs_to :patient

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  has_one :exotel_phone_number_detail

  default_scope -> { order(device_created_at: :asc) }

  EXOTEL_RE_REQUEST_WHITELIST_MONTHS = ENV["EXOTEL_RE_REQUEST_WHITELIST_MONTHS"].to_i.months || 6.months

  def self.require_whitelisting
    left_outer_joins(:exotel_phone_number_detail)
      .where(patient_phone_numbers: {dnd_status: true})
      .where.not(patient_phone_numbers: {phone_type: "invalid"})
      .where(%(
        (exotel_phone_number_details.whitelist_status is null) OR
        (exotel_phone_number_details.whitelist_status = 'neutral') OR
        (exotel_phone_number_details.whitelist_status = 'requested' AND exotel_phone_number_details.whitelist_requested_at <= '#{EXOTEL_RE_REQUEST_WHITELIST_MONTHS.ago}') OR
        (exotel_phone_number_details.whitelist_status = 'whitelist' AND exotel_phone_number_details.whitelist_status_valid_until <= '#{Time.current}')))
  end

  def update_exotel_phone_number_detail(attributes)
    transaction do
      update!(attributes.slice(:dnd_status, :phone_type))
      if exotel_phone_number_detail.present?
        exotel_phone_number_detail.update!(attributes.slice(:whitelist_status, :whitelist_status_valid_until))
      else
        ExotelPhoneNumberDetail.create!(
          {patient_phone_number_id: id}
            .merge(attributes.slice(:whitelist_status, :whitelist_status_valid_until))
        )
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
