class Address < ApplicationRecord
  include Mergeable

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def in_punjab?
    state.strip.downcase == 'punjab'
  end

  def in_maharashtra?
    state.strip.downcase == 'maharashtra'
  end
end
