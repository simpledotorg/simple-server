class FacilityGroup < ApplicationRecord
  extend FriendlyId
  default_scope -> { kept }

  belongs_to :organization
  belongs_to :protocol

  has_many :facilities, dependent: :nullify
  has_many :users, through: :facilities

  has_many :admin_access_controls, as: :access_controllable
  has_many :admins, through: :admin_access_controls

  has_many :patients, through: :facilities, source: :registered_patients
  has_many :blood_pressures, through: :facilities
  has_many :encounters, through: :facilities
  has_many :prescription_drugs, through: :facilities
  has_many :appointments, through: :facilities

  has_many :medical_histories, through: :patients
  has_many :communications, through: :appointments

  validates :name, presence: true
  validates :organization, presence: true

  friendly_id :name, use: :slugged

  def report_on_patients
    Patient.where(registration_facility: facilities)
  end
end
