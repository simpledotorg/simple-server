class PatientPhoneNumber < ApplicationRecord
  include Mergeable

  PHONE_TYPE = %w[mobile landline].freeze
  validates_presence_of :number, :created_at, :updated_at
  belongs_to :patient

  def errors_hash
    errors.to_hash.merge(id: id)
  end
end
