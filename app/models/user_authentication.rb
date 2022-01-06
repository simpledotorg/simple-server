# frozen_string_literal: true

class UserAuthentication < ApplicationRecord
  belongs_to :user
  belongs_to :authenticatable, polymorphic: true

  validates_uniqueness_of :authenticatable_id, scope: [:user_id, :authenticatable_type]
end
