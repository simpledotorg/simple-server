class AppointmentPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: :view_overdue_list)
      .present?
  end

  def update?
    user_has_any_permissions?(
      [:view_overdue_list, nil],
      [:view_overdue_list, record.facility.organization],
      [:view_overdue_list, record.facility.facility_group],
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
      required_permission = user.user_permissions.find_by(permission_slug: :view_overdue_list)
      return scope.none unless required_permission.present?

      resource = required_permission.resource
      return scope.all unless resource.present?

      scope.where(facility: resource.facilities)
    end
  end
end
