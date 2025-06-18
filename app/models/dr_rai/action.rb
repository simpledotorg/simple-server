class DrRai::Action < ApplicationRecord
  default_scope { order(created_at: :asc) }
end
