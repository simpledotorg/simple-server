class Address < ApplicationRecord
  include Mergeable

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def in_punjab?
    state.trim.downcase == 'punjab'
  end

  def in_maharashtra?
    state.trim.downcase == 'maharashtra'
  end
end
