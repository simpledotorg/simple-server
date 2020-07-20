class Upcoming::Viewer::FacilityPolicy < Upcoming::ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      Facility.where(id: user.accesses.map(&:resource).map(&:facilities))
    end
  end
end
