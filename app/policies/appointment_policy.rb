class AppointmentPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_access_appointment_information_for_all_organizations,
     :can_access_appointment_information_for_organization,
     :can_access_appointment_information_for_facility_group,
     :can_access_appointment_information_for_facility
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def update?
    user_has_any_permissions?(
      :can_access_appointment_information_for_all_organizations,
      [:can_access_appointment_information_for_organization, record.facility.organization],
      [:can_access_appointment_information_for_facility_group, record.facility.facility_group],
      [:can_access_appointment_information_for_facility, record.facility]
    )
  end

  def edit?
    update?
  end

  def download?
    user_has_any_permissions?(
      :can_access_appointment_information_for_all_organizations,
      [:can_access_appointment_information_for_organization, record.facility.organization],
      [:can_access_appointment_information_for_facility_group, record.facility.facility_group],
      [:can_access_appointment_information_for_facility, record.facility]
    )
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(
        facility: resources_for_permission(:can_manage_overdue_list_for_facility) +
          resources_for_permission(:can_download_overdue_list_for_facility))
    end
  end
end
