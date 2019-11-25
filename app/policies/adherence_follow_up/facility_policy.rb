class AdherenceFollowUp::FacilityPolicy < ApplicationPolicy

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:view_adherence_follow_up_list)

      facility_group_ids = facility_group_ids_for_permission(:view_adherence_follow_up_list)
      return scope.all unless facility_group_ids.present?

      scope.where(facility_group_id: facility_group_ids)
    end
  end
end