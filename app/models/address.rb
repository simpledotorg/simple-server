class Address < ApplicationRecord
  include Mergeable

  def errors_hash
    errors.to_hash.merge(id: id)
  end
end
