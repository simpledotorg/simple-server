class PatientPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:view_adherence_follow_up_list_for_all_organizations,
     :view_adherence_follow_up_list_for_organization,
     :view_adherence_follow_up_list_for_facility_group,
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def update?
    user_has_any_permissions?(
      :view_adherence_follow_up_list_for_all_organizations,
      [:view_adherence_follow_up_list_for_organization, record.registration_facility.organization],
      [:view_adherence_follow_up_list_for_facility_group, record.registration_facility.facility_group],
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
      if user.has_permission?(:view_adherence_follow_up_list_for_all_organizations)
        scope.all
      elsif user.has_permission?(:view_adherence_follow_up_list_for_organization)
        scope.where(registration_facility: resources_for_permission(:view_adherence_follow_up_list_for_organization)
                                             .flat_map(&:facilities))
      elsif user.has_permission?(:view_adherence_follow_up_list_for_facility_group)
        scope.where(registration_facility: resources_for_permission(:view_adherence_follow_up_list_for_facility_group)
                                             .flat_map(&:facilities))
      else
        scope.none
      end
    end
  end
end
