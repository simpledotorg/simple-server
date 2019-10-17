class Manage::FacilityPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_organizations, :manage_facility_groups, :manage_facilities])
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization],
      [:manage_facility_groups, record.facility_group],
      [:manage_facilities, record.facility_group]
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?([:manage_organizations, nil])
  end

  def create?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization],
      [:manage_facility_groups, record.facility_group],
      [:manage_facilities, record.facility_group]
    )
  end

  def new?
    create?
  end

  def update?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization],
      [:manage_facility_groups, record.facility_group],
      [:manage_facilities, record.facility_group]
    )
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && create?
  end

  def upload?
    user.user_permissions
      .where(permission_slug: [:manage_organizations, :manage_facility_groups, :manage_facilities])
      .present?
  end

  def destroyable?
    record.registered_patients.none? && record.blood_pressures.none?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.user_permissions.where(permission_slug: [
        :manage_organizations,
        :manage_facility_groups,
        :manage_facilities
      ])

      return scope.all if user.has_permission?(:manage_organizations)

      facility_group_ids = []

      if user.has_permission?(:manage_facility_groups)
        facility_group_ids = facility_group_ids_for_permission(:manage_facility_groups)
      elsif user.has_permission?(:manage_facilities)
        facility_group_ids = facility_group_ids_for_permission(:manage_facilities)
      end

      scope.where(facility_group_id: facility_group_ids)
    end
  end
end
