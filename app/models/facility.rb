class Facility < ApplicationRecord
  include Mergeable

  has_many :facility_patients
  has_many :patients, through: :facility_patients

  validates :name, presence: true
  validates :district, presence: true
  validates :state, presence: true
  validates :country, presence: true
end
