class Upcoming::FacilityGroupPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def manage?
    admin_accesses = user.accesses.admin
    organizations = Organization.includes(:facility_groups).where(facility_groups: record)
    admin_accesses.where(resource: organizations).or(admin_accesses.where(resource: record)).exists?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
