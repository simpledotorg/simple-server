class FacilityPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_organizations, :manage_facility_groups, :manage_facilities])
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization],
      [:manage_facilities, record.facility_group]
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?([:manage_organizations, nil])
  end

  def whatsapp_graphics?
    show?
  end

  def patient_list?
    whatsapp_graphics?
  end

  def create?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization],
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

  def download_overdue_list?
    user_has_any_permissions?(
      [:download_overdue_list, nil],
      [:download_overdue_list, record.organization],
      [:download_overdue_list, record.facility_group],
    )
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
      if user.has_permission?(:manage_organizations)
        return scope.all
      elsif user.has_permission?(:manage_facility_groups)
        facility_groups = facility_groups_for_permission(:manage_facility_groups)
        return scope.where(facility_group: facility_groups)
      elsif user.has_permission(:view_overdue_list)
        facility_groups = facility_groups_for_permission(:view_overdue_list)
        return scope.where(facility_group: facility_groups)
      elsif user.has_permission(:approve_health_workers)
        facility_groups = facility_groups_for_permission(:approve_health_workers)
        return scope.where(facility_group: facility_groups)
      elsif user.has_permission?(:manage_facilities)
        return scope.where(facility_group: resources_for_permission(:manage_facilities))
      end

      scope.none
    end

    def facility_groups_for_permission(slug)
      resources = resources_for_permission(:manage_facility_groups)
      resources.flat_map do |resource|
        if resource.is_a? Organization
          resource.facility_groups
        elsif resource.is_a FacilityGroup
          resource
        end
      end
    end
  end
end
