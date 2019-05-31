class FacilityPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner? || user.supervisor?
  end

  def show?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record.organization],
      [:can_view_facilities_in_facility_group, record.facility_group]
    )
  end

  def create?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record.organization]
    )
  end

  def new?
    create?
  end

  def update?
    create?
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && create?
  end

  private

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
      if user.has_permission?(:can_manage_all_organizations)
        return scope.all
      elsif user.has_permission?(:can_manage_facility_groups_for_organization)
        facility_groups = resources_for_permission(:can_manage_facility_groups_for_organization).flat_map(&:facility_groups)
        return scope.where(facility_group: facility_groups)
      elsif user.has_permission?(:can_view_facilities_in_facility_group)
        return scope.where(facility_group: resources_for_permission(:can_view_facilities_in_facility_group))
      end

      scope.none
    end
  end
end
