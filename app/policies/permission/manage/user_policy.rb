class Permission::Manage::UserPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def manage_user?
    user.role.permissions.manage_users.exists?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.role.permissions.where(name: "manage_users").present?
      user_scope = scope.joins(:phone_number_authentications).where.not(phone_number_authentications: {id: nil})

      resources_join = Organization.joins(facility_groups: :facilities)
      resources = user.user_resources.group_by(&:resource_type)

      facility_ids = resources_join.where(organizations: {id: resources["Organization"]&.map(&:resource_id)})
        .or(resources_join.where(facility_groups: {id: resources["FacilityGroup"]&.map(&:resource_id)}))
        .or(resources_join.where(facilities: {id: resources["Facility"]&.map(&:resource_id)}))
        .pluck("facilities.id")

      user_scope.where(phone_number_authentications: {registration_facility_id: facility_ids})
    end
  end
end
