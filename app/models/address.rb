# frozen_string_literal: true

class Address < ApplicationRecord
  include Mergeable
  include PgSearch::Model

  pg_search_scope :search_by_street_or_village,
    against: {street_address: "B", village_or_colony: "A"}, using: {tsearch: {prefix: true, any_word: true}}

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def has_street_address?
    street_address.present?
  end
end
