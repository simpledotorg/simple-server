class DrugStock < ApplicationRecord
  belongs_to :facility
  belongs_to :user
  belongs_to :protocol_drug

  validates :in_stock, numericality: true, presence: true
  validates :received, numericality: true
  validates :recorded_at, presence: true
end
