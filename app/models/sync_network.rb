class SyncNetwork < ApplicationRecord
  belongs_to :organisation
  has_many :facilities

  validates :name, presence: true
  validates :organisation, presence: true
end
