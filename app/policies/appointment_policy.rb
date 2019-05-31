class AppointmentPolicy < ApplicationPolicy
  def index?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_overdue_list_for_facility, record] # record is facility because of the way we use it in the controller
    )
  end

  def edit?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_overdue_list_for_facility, record.facility]
    )
  end

  def update?
    edit?
  end

  def download?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_download_overdue_list_for_facility, record]
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
