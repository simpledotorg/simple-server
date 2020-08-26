class OverdueList::PatientPolicy < ApplicationPolicy
  def lookup?
    user.has_permission?(:view_overdue_list)
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

      scope.where(registration_facility_id: facility_ids)
    end
  end
end
