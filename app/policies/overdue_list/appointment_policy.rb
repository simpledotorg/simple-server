class OverdueList::AppointmentPolicy < ApplicationPolicy
  def index?
    user.has_permission?(:view_overdue_list)
  end

  def update?
    user_has_any_permissions?(
      [:view_overdue_list, nil],
      [:view_overdue_list, record.facility.organization],
      [:view_overdue_list, record.facility.facility_group]
    )
  end

  def edit?
    update?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      super
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:view_overdue_list)

      facility_ids = facility_ids_for_permission(:view_overdue_list)
      return scope.all unless facility_ids.present?

      scope.where(facility_id: facility_ids)
    end
  end
end
