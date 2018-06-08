class Facility < ApplicationRecord
  include Mergeable

  has_many :users
  has_many :blood_pressures
  has_many :patients, through: :blood_pressures

  validates :name, presence: true
  validates :district, presence: true
  validates :state, presence: true
  validates :country, presence: true
end
