class Address < ApplicationRecord
  include Mergeable

  validates_presence_of :created_at, :updated_at

  def errors_hash
    errors.to_hash.merge(id: id)
  end
end
