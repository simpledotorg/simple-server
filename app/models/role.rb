class Role < ApplicationRecord
  has_and_belongs_to_many :permissions
  has_many :users

  enum name: {
    super_admin: "super_admin",
    admin: "admin",
    owner: "owner",
    analyst: "analyst"
  }
end
