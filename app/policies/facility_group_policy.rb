class FacilityGroupPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_organizations, :manage_facility_groups])
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization]
    )
  end

  def create?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization]
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

  def whatsapp_graphics?
    show?
  end

  private

  def destroyable?
    record.facilities.none? && record.patients.none? && record.blood_pressures.none?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:manage_organizations)
        scope.all
      elsif user.has_permission?(:manage_facility_groups)
        scope.where(organization: resources_for_permission(:manage_facility_groups))
      else
        scope.none
      end
    end
  end
end
