class AuditLogPolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.owner?
        scope.all
      else
        scope.none
      end
    end
  end
end
