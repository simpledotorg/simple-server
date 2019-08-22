class FacilityGroupPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_manage_all_organizations,
     :can_manage_an_organization,
     :can_manage_a_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record.organization],
      [:can_manage_a_facility_group, record]
    )
  end

  def create?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record.organization]
    )
  end

  def new?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_manage_all_organizations,
     :can_manage_an_organization
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def update?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record.organization]
    )
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record.organization]
    )
  end

  def whatsapp_graphics?
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
      if user.has_permission?(:can_manage_all_organizations)
        scope.all
      elsif user.has_permission?(:can_manage_an_organization)
        scope.where(organization: resources_for_permission(:can_manage_an_organization))
      elsif user.has_permission?(:can_manage_a_facility_group)
        scope.where(id: resources_for_permission(:can_manage_a_facility_group).map(&:id))
      else
        scope.none
      end
    end
  end
end
