class Facility < ApplicationRecord
  include Mergeable

  validates :name, presence: true
  validates :district, presence: true
  validates :state, presence: true
  validates :country, presence: true
end
