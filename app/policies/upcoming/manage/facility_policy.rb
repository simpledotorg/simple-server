class Upcoming::Manage::FacilityPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      Facility.where(id: user.admin.accesses.map(&:resource).map(&:facilities))
    end
  end
end
