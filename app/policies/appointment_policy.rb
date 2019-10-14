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
      return scope.none unless user.has_permission?(:view_overdue_list)

      facility_ids = facility_ids_for_slug(:view_overdue_list)
      return scope.all unless facility_ids.present?

      scope.where(facility_id: facility_ids)
    end

    def facility_ids_for_slug(slug)
      resources = resources_for_permission(slug)

      resources.flat_map do |resource|
        resource.facilities.map(&:id)
      end.uniq.compact
    end
  end
end
