class CohortReport::UserPolicy < ApplicationPolicy
  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      super
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:view_cohort_reports)

      facility_ids = facility_ids_for_permission(:view_cohort_reports)
      user_scope = scope.joins(:phone_number_authentications)
        .where.not(phone_number_authentications: {id: nil})

      return user_scope.all if facility_ids.blank?

      user_scope.where(phone_number_authentications:
                         {registration_facility_id: facility_ids})
    end
  end
end
