class Address < ApplicationRecord
  include Mergeable

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def state_to_sym
    state.strip.split(' ').join('_').downcase.to_sym
  end
end
