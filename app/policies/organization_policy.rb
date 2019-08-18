class OrganizationPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_manage_all_organizations,
     :can_manage_an_organization,
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record]
    )
  end

  def create?
    user_has_any_permissions?(:can_manage_all_organizations)
  end

  def new?
    create?
  end

  def update?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record]
    )
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && user_has_any_permissions?(:can_manage_all_organizations)
  end

  private

  def destroyable?
    record.facility_groups.none?
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
        scope.where(id: resources_for_permission(:can_manage_an_organization).map(&:id))
      elsif user.has_permission?(:can_manage_a_facility_group)
        scope.where(id: resources_for_permission(:can_manage_a_facility_group).map(&:organization_id))
      else
        scope.none
      end
    end
  end
end
