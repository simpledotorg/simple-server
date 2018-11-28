class Organisation < ApplicationRecord
  validates :name, presence: true
end
