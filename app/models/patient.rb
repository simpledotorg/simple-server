class Patient < ApplicationRecord
  GENDERS  = %w[male female transgender].freeze
  STATUSES = %w[active dead migrated unresponsive inactive].freeze

  belongs_to :address, optional: true
  has_many :patient_phone_numbers
  has_many :phone_numbers, through: :patient_phone_numbers

  validates_presence_of :created_at, :updated_at
  validates_inclusion_of :gender, in: GENDERS
  validates_inclusion_of :status, in: STATUSES
  validate :presence_of_age

  def presence_of_age
    unless date_of_birth.present? || age_when_created.present?
      errors.add(:age, 'Either date_of_birth or age_when_created should be present')
    end
  end

  def self.new_patient_from_nested_params(params)
    address       = Address.new(params['address']) if params['address'].present?
    phone_numbers = []
    if params['phone_numbers'].present?
      phone_numbers = params['phone_numbers'].map do |phone_number_params|
        PhoneNumber.new(phone_number_params)
      end
    end

    patient               = Patient.new(params.except(:address, :phone_numbers))
    patient.address       = address
    patient.phone_numbers = phone_numbers
    patient
  end

end
