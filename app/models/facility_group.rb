class FacilityGroup < ApplicationRecord
  belongs_to :organization
  has_many :facilities, dependent: :nullify
  has_many :users, through: :facilities

  has_many :admin_access_controls
  has_many :admins, through: :admin_access_controls

  has_many :patients, through: :facilities, source: :registered_patients
  has_many :blood_pressures, through: :facilities
  has_many :prescription_drugs, through: :facilities
  has_many :appointments, through: :facilities

  has_many :medical_histories, through: :patients
  has_many :communications, through: :appointments

  validates :name, presence: true
  validates :organization, presence: true
end
