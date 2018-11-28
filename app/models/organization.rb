class Organization < ApplicationRecord
  has_many :facility_groups

  validates :name, presence: true
end
