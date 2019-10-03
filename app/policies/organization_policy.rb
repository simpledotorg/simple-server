class OrganizationPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:manage_organizations,
     :manage_facility_groups_for_organization,
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
    user_has_any_permissions?(
      :manage_organizations,
      [:manage_facility_groups_for_organization, record]
    )
  end

  def create?
    user_has_any_permissions?(:manage_organizations)
  end

  def new?
    create?
  end

  def update?
    user_has_any_permissions?(
      :manage_organizations,
      [:manage_facility_groups_for_organization, record]
    )
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && user_has_any_permissions?(:manage_organizations)
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
      if user.has_permission?(:manage_organizations)
        scope.all
      elsif user.has_permission?(:manage_facility_groups_for_organization)
        scope.where(id: resources_for_permission(:manage_facility_groups_for_organization).map(&:id))
      elsif user.has_permission?(:manage_facilities_for_facility_group)
        scope.where(id: resources_for_permission(:manage_facilities_for_facility_group).map(&:organization_id))
      else
        scope.none
      end
    end
  end
end
