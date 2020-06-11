class AdherenceFollowUp::PatientPolicy < ApplicationPolicy
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
      return scope.none unless user.has_permission?(:view_adherence_follow_up_list)

      facility_ids = facility_ids_for_permission(:view_adherence_follow_up_list)
      return scope.all unless facility_ids.present?

      scope.where(registration_facility_id: facility_ids)
    end
  end
end
