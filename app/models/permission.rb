class Permission < ApplicationRecord
  has_and_belongs_to_many :roles

  enum name: {
    manage_region: "manage_region",
    manage_users: "manage_users",
    access_aggregate_data: "access_aggregate_data",
    access_pii: "access_pii"
  }
end
