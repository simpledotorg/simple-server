class CphcFacilityMapping < ApplicationRecord
  include PgSearch::Model

  def auth_token
    encrypted_cphc_auth_token && decrypt(encrypted_cphc_auth_token)
  end

  def auth_token=(unencrypted_auth_token)
    self.encrypted_cphc_auth_token = encrypt(unencrypted_auth_token)
  end

  def self.with_user(facility)
    facility.cphc_facility_mappings.where.not(cphc_user_details: nil).first
  end

  def cphc_user
    if auth_token.present?
      cphc_user_details&.merge(user_authorization: auth_token)&.with_indifferent_access
    else
      OneOff::CphcEnrollment::AuthManager.new(auth_token: ENV["CPHC_AUTH_TOKEN"]).user
    end
  end

  validates_uniqueness_of :cphc_village_id, scope: [
    :cphc_state_id,
    :cphc_state_name,
    :cphc_district_id,
    :cphc_district_name,
    :cphc_taluka_id,
    :cphc_taluka_name,
    :cphc_phc_id,
    :cphc_phc_name,
    :cphc_subcenter_id,
    :cphc_subcenter_name,
    :cphc_village_name
  ]

  belongs_to :facility, optional: true

  pg_search_scope :search_by_facility,
    against: :cphc_phc_name,
    using: {tsearch: {any_word: true, prefix: true}}

  pg_search_scope :search_by_subcenter,
                  against: :cphc_subcenter_name,
                  using: {tsearch: {any_word: true, prefix: true}}

  pg_search_scope :search_by_region, against: {
    cphc_district_name: "A",
    cphc_taluka_name: "B"
  }, using: {tsearch: {any_word: true, prefix: true}}

  pg_search_scope :search_by_village, against: {
    cphc_village_name: "A"
  }, using: {tsearch: {prefix: true}}

  def decrypt(value)
    ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31]).decrypt_and_verify(value)
  end

  def encrypt(value)
    ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31]).encrypt_and_sign(value)
  end
end
