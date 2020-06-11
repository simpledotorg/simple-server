class FacilityGroup < ApplicationRecord
  extend FriendlyId
  default_scope -> { kept }

  belongs_to :organization
  belongs_to :protocol

  has_many :facilities, dependent: :nullify
  has_many :users, through: :facilities

  has_many :patients, through: :facilities, source: :registered_patients
  has_many :blood_pressures, through: :facilities
  has_many :blood_sugars, through:  :facilities
  has_many :encounters, through: :facilities
  has_many :prescription_drugs, through: :facilities
  has_many :appointments, through: :facilities

  has_many :medical_histories, through: :patients
  has_many :communications, through: :appointments

  validates :name, presence: true
  validates :organization, presence: true

  friendly_id :name, use: :slugged

  auto_strip_attributes :name, squish: true, titleize: true

  def report_on_patients
    Patient.where(registration_facility: facilities)
  end
end
