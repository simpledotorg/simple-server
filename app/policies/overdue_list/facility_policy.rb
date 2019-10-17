class OverdueList::FacilityPolicy < ApplicationPolicy

  def download?
    user_has_any_permissions?(
      [:download_overdue_list, nil],
      [:download_overdue_list, record.organization],
      [:download_overdue_list, record.facility_group],
    )
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:view_overdue_list)

      facility_groups = facility_groups_for_permission(:view_overdue_list)
      return scope unless facility_groups.present?

      scope.where(facility_group: facility_groups)
    end
  end
end