class Address < ApplicationRecord
  validates_presence_of :created_at, :updated_at

  alias_method :has_errors?, :invalid?

  def errors_hash
    errors.to_hash.merge(id: id)
  end
end
