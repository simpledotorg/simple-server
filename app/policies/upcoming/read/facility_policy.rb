class Upcoming::Read::FacilityPolicy < Upcoming::ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.super_admin?
      scope.where(id: user.accesses.facilities)
    end
  end
end
