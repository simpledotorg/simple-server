class PatientPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_access_patient_information_for_all_organizations,
     :can_access_patient_information_for_organization,
     :can_access_patient_information_for_facility_group,
     :can_access_patient_information_for_facility
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def update?
    user_has_any_permissions?(
      :can_access_patient_information_for_all_organizations,
      [:can_access_patient_information_for_organization, record.registration_facility.organization],
      [:can_access_patient_information_for_facility_group, record.registration_facility.facility_group],
      [:can_access_patient_information_for_facility, record.registration_facility]
    )
  end

  def edit?
    update?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:can_access_patient_information_for_all_organizations)
        scope.all
      elsif user.has_permission?(:can_access_patient_information_for_organization)
        scope.where(registration_facility: resources_for_permission(:can_access_patient_information_for_organization)
                                             .flat_map(&:facilities))
      elsif user.has_permission?(:can_access_patient_information_for_facility_group)
        scope.where(registration_facility: resources_for_permission(:can_access_patient_information_for_facility_group)
                                             .flat_map(&:facilities))
      elsif user.has_permission?(:can_access_patient_information_for_facility)
        scope.where(registration_facility: resources_for_permission(:can_access_patient_information_for_facility))
      else
        scope.none
      end
    end
  end
end
