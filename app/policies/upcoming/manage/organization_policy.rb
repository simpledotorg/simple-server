class Upcoming::Manage::OrganizationPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
    user.accesses.admin.where(resource: record).exists?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      Organization.where(id: user.admin.accesses.map(&:resource).map(&:organizations))
    end
  end
end
