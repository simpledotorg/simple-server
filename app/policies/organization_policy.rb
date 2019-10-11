class OrganizationPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_organizations, :manage_facility_groups])
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record]
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
      [:manage_organizations, nil],
      [:manage_facility_groups, record]
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
      elsif user.has_permission?(:manage_facility_groups)
        scope.where(id: resources_for_permission(:manage_facility_groups).map(&:id))
      elsif user.has_permission?(:view_cohort_reports)
        scope.where(id: cohort_report_organization_ids)
      else
        scope.none
      end
    end

    def cohort_report_organization_ids
      resources = resources_for_permission(:view_cohort_reports)
      resources.map do |resource|
        if resource.is_a? Organization
          resource.id
        else
          resource.organization.id
        end
      end
    end
  end
end