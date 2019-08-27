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
    update?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:can_access_appointment_information_for_all_organizations)
        scope.all
      elsif user.has_permission?(:can_access_appointment_information_for_organization)
        scope.where(facility: resources_for_permission(:can_access_appointment_information_for_organization)
                                .flat_map(&:facilities))
      elsif user.has_permission?(:can_access_appointment_information_for_facility_group)
        scope.where(facility: resources_for_permission(:can_access_appointment_information_for_facility_group)
                                .flat_map(&:facilities))
      elsif user.has_permission?(:can_access_appointment_information_for_facility)
        scope.where(facility: resources_for_permission(:can_access_appointment_information_for_facility))
      else
        scope.none
      end
    end
  end
end
