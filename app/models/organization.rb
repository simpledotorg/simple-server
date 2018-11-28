class Organization < ApplicationRecord
  has_many :sync_networks

  validates :name, presence: true
end
