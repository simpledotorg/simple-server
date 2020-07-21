class Upcoming::Read::FacilityPolicy < Upcoming::ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.super_admin?
      Facility.where(id: user.accesses.map(&:resource).map(&:facilities))
    end
  end
end
