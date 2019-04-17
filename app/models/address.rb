class Address < ApplicationRecord
  include Mergeable

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end
