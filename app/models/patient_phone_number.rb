class PatientPhoneNumber < ApplicationRecord
  include Mergeable

  PHONE_TYPE = %w[mobile landline].freeze
  belongs_to :patient

  def errors_hash
    errors.to_hash.merge(id: id)
  end
end
