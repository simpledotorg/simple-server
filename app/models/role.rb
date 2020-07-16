class Role < ApplicationRecord
  enum name: {
    super_admin: "super_admin",
    admin: "admin",
    analyst: "analyst"
  }
end
