class Patient < ApplicationRecord
  include Mergeable

  GENDERS  = %w[male female transgender].freeze
  STATUSES = %w[active dead migrated unresponsive inactive].freeze

  belongs_to :address, optional: true
  has_many :phone_numbers, class_name: 'PatientPhoneNumber'
  has_many :blood_pressures
  has_many :prescription_drugs
  has_many :facilities, -> { distinct }, through: :blood_pressures
  has_many :users, -> { distinct }, through: :blood_pressures

  belongs_to :registration_facility, class_name: "Facility", optional: true
  belongs_to :registration_user, class_name: "User"

  has_many :appointments
  has_one :medical_history

  validate :past_date_of_birth

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  validates_associated :address, if: :address
  validates_associated :phone_numbers, if: :phone_numbers

  def past_date_of_birth
    if date_of_birth.present? && date_of_birth > Date.today
      errors.add(:date_of_birth, "can't be in the future")
    end
  end

  def latest_scheduled_appointment
    return appointments.where(status: 'scheduled').order(scheduled_date: :desc).first
  end

  def latest_blood_pressure
    blood_pressures.order(device_created_at: :desc).first
  end
end
