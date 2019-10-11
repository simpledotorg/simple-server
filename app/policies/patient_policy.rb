class PatientPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: :view_adherence_follow_up_list)
      .present?
  end

  def update?
    user_has_any_permissions?(
      [:view_adherence_follow_up_list, nil],
      [:view_adherence_follow_up_list, record.registration_facility.organization],
      [:view_adherence_follow_up_list, record.registration_facility.facility_group],
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
      required_permission = user.user_permissions.find_by(permission_slug: :view_adherence_follow_up_list)
      return scope.none unless required_permission.present?

      resource = required_permission.resource
      return scope.all unless resource.present?

      scope.where(registration_facility: resource.facilities)
    end
  end
end
