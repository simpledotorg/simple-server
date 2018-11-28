class SyncNetwork < ApplicationRecord
  belongs_to :organisation

  validates :organisation, presence: true
end
