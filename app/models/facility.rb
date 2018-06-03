class Facility < ApplicationRecord
  validates :name, presence: true
  validates :district, presence: true
  validates :state, presence: true
  validates :country, presence: true
end
