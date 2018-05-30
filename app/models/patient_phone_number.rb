class PatientPhoneNumber < ApplicationRecord
  include Mergeable

  PHONE_TYPE = %w[mobile landline].freeze
  belongs_to :patient
end
