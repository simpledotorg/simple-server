class Address < ApplicationRecord
  include Mergeable
  include PgSearch::Model

  STATE_TO_LOCALE = {
    punjab: "pa-Guru-IN",
    maharashtra: "mr-IN",
    karnataka: "kn-IN"
  }

  pg_search_scope :search_by_street_or_village,
    against: {street_address: "B", village_or_colony: "A"}, using: {tsearch: {prefix: true, any_word: true}}

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def locale
    STATE_TO_LOCALE.fetch(state_to_sym, :en)
  end

  def has_street_address?
    street_address.present?
  end

  private

  def state_to_sym
    state.strip.split(" ").join("_").downcase.to_sym
  end
end
