class FacilityPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:manage_organizations,
     :manage_facility_groups_for_organization,
     :manage_facilities_for_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
    user_has_any_permissions?(
      :manage_organizations,
      [:manage_facility_groups_for_organization, record.organization],
      [:manage_facilities_for_facility_group, record.facility_group]
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?(:manage_organizations)
  end

  def whatsapp_graphics?
    show?
  end

  def patient_list?
    whatsapp_graphics?
  end

  def create?
    user_has_any_permissions?(
      :manage_organizations,
      [:manage_facility_groups_for_organization, record.organization],
      [:manage_facilities_for_facility_group, record.facility_group]
    )
  end

  def new?
    create?
  end

  def update?
    user_has_any_permissions?(
      :manage_organizations,
      [:manage_facility_groups_for_organization, record.organization],
      [:manage_facilities_for_facility_group, record.facility_group]
    )
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && create?
  end

  def upload?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:manage_organizations,
     :manage_facility_groups_for_organization,
     :manage_facilities_for_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def download_overdue_list?
    user_has_any_permissions?(
      :download_overdue_list_for_all_organizations,
      [:download_overdue_list_for_organization, record.organization],
      [:download_overdue_list_for_facility_group, record.facility_group],
    )
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
      elsif user.has_permission?(:manage_facility_groups_for_organization)
        facility_groups = resources_for_permission(:manage_facility_groups_for_organization).flat_map(&:facility_groups)
        return scope.where(facility_group: facility_groups)
      elsif user.has_permission?(:manage_facilities_for_facility_group)
        return scope.where(facility_group: resources_for_permission(:manage_facilities_for_facility_group))
      elsif user.has_permission?(:view_overdue_list_for_facility_group)
        return scope.where(facility_group: resources_for_permission(:view_overdue_list_for_facility_group))
      elsif user.has_permission?(:view_adherence_follow_up_list_for_facility_group)
        return scope.where(facility_group: resources_for_permission(:view_adherence_follow_up_list_for_facility_group))
      elsif user.has_permission?(:view_overdue_list_for_organization)
        return scope.where(organization: resources_for_permission(:view_overdue_list_for_organization))
      end

      scope.none
    end
  end

  private

  def destroyable?
    record.registered_patients.none? && record.blood_pressures.none?
  end
end
