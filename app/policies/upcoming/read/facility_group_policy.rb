class Upcoming::Read::FacilityGroupPolicy < Upcoming::ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.super_admin?
      scope.where(id: user.accesses.facility_groups)
    end
  end
end
