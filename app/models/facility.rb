class Facility < ApplicationRecord
  include Mergeable

  has_many :users, foreign_key: 'registration_facility_id'
  has_many :blood_pressures
  has_many :patients, -> { distinct }, through: :blood_pressures
  has_many :prescription_drugs

  has_many :registered_patients, class_name: "Patient", foreign_key: "registration_facility_id"

  has_many :appointments

  belongs_to :facility_group, optional: true

  validates :name, presence: true
  validates :district, presence: true
  validates :state, presence: true
  validates :country, presence: true
  validates :pin, numericality: true, allow_blank: true

  delegate :protocol, to: :facility_group, allow_nil: true
end
