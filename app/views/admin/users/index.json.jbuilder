# frozen_string_literal: true

json.array! @users, partial: "admin/users/user", as: :user
