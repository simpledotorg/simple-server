class Address < ApplicationRecord
  validates_presence_of :created_at, :updated_at
end
