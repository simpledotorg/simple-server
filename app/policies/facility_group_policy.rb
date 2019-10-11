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
    index?
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
        scope.where(id: facility_group_ids_for_permission(:manage_facility_groups))
      elsif user.has_permission?(:view_cohort_reports)
        scope.where(id: facility_group_ids_for_permission(:view_cohort_reports))
      else
        scope.none
      end
    end


    def facility_group_ids_for_permission(slug)
      resources = resources_for_permission(slug)
      resources.flat_map do |resource|
        if resource.is_a? Organization
          resource.facility_groups.map(&:id)
        elsif resource.is_a? FacilityGroup
          resource.id
        end
      end
    end
  end
end
