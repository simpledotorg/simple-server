class FacilityPolicy < ApplicationPolicy
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
      [:can_manage_a_facility_group, record.facility_group]
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?(:can_manage_all_organizations)
  end

  def whatsapp_graphics?
    show?
  end

  def create?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record.organization],
      [:can_manage_a_facility_group, record.facility_group]
    )
  end

  def new?
    create?
  end

  def update?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record.organization],
      [:can_manage_a_facility_group, record.facility_group]
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
    [:can_manage_all_organizations,
     :can_manage_an_organization,
     :can_manage_a_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def download_overdue_list?
    user_has_any_permissions?(
      :can_access_appointment_information_for_all_organizations,
      [:can_access_appointment_information_for_organization, record.organization],
      [:can_access_appointment_information_for_facility_group, record.facility_group],
      [:can_access_appointment_information_for_facility, record]
    )
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
      elsif user.has_permission?(:can_manage_an_organization)
        facility_groups = resources_for_permission(:can_manage_an_organization).flat_map(&:facility_groups)
        return scope.where(facility_group: facility_groups)
      elsif user.has_permission?(:can_manage_a_facility_group)
        return scope.where(facility_group: resources_for_permission(:can_manage_a_facility_group))
      elsif user.has_permission?(:can_access_appointment_information_for_facility_group)
        return scope.where(facility_group: resources_for_permission(:can_access_appointment_information_for_facility_group))
      elsif user.has_permission?(:can_access_patient_information_for_facility_group)
        return scope.where(facility_group: resources_for_permission(:can_access_patient_information_for_facility_group))
      elsif user.has_permission?(:can_access_appointment_information_for_organization)
        return scope.where(organization: resources_for_permission(:can_access_appointment_information_for_organization))
      end

      scope.none
    end
  end

  private

  def destroyable?
    record.registered_patients.none? && record.blood_pressures.none?
  end
end
