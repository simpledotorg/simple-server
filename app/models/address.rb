class Address < ApplicationRecord
  include Mergeable

  STATE_TO_LOCALE = {
    punjab: :pa_Guru_IN,
    maharashtra: :mr_IN,
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def locale
    STATE_TO_LOCALE.fetch(state_to_sym, :en)
  end

  private

  def state_to_sym
    state.strip.split(' ').join('_').downcase.to_sym
  end
end
