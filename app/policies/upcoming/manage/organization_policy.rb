class Upcoming::Manage::OrganizationPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
    return true if user.super_admin?
    user.accesses.admin.where(resource: resolve_record(record, Organization)).exists?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.super_admin?
      Organization.where(id: user.accesses.admin.map(&:resource).map(&:organizations))
    end
  end
end
