class AppointmentPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:view_overdue_list_for_all_organizations,
     :view_overdue_list_for_organization,
     :view_overdue_list_for_facility_group,
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def update?
    user_has_any_permissions?(
      :view_overdue_list_for_all_organizations,
      [:view_overdue_list_for_organization, record.facility.organization],
      [:view_overdue_list_for_facility_group, record.facility.facility_group],
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
      if user.has_permission?(:view_overdue_list_for_all_organizations)
        scope.all
      elsif user.has_permission?(:view_overdue_list_for_organization)
        scope.where(facility: resources_for_permission(:view_overdue_list_for_organization)
                                .flat_map(&:facilities))
      elsif user.has_permission?(:view_overdue_list_for_facility_group)
        scope.where(facility: resources_for_permission(:view_overdue_list_for_facility_group)
                                .flat_map(&:facilities))
      else
        scope.none
      end
    end
  end
end
