class FacilityGroupPolicy < ApplicationPolicy
  def index?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record]
    )
  end

  def show?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record.organization]
    )
  end

  def create?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record.organization]
    )
  end

  def new?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record.organization]
    )
  end

  def update?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record.organization]
    )
  end

  def edit?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record.organization]
    )
  end

  def destroy?
    destroyable? && user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_facility_groups_for_organization, record.organization]
    )
  end

  def graphics?
    show?
  end

  private

  def destroyable?
    record.facilities.none? && record.patients.none? && record.blood_pressures.none?
  end

  def admin_can_access?(role)
    user.role == role.to_s && user.facility_groups.include?(record)
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.authorized?(:can_manage_all_organizations)
        scope.all
      else
        scope.where(organization: resources_for_permission(:can_manage_facility_groups_for_organization))
      end
    end
  end
end
