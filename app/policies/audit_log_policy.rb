class AuditLogPolicy < ApplicationPolicy
  def index?
    user_has_any_permissions?(:view_audit_logs)
  end

  def show?
    user_has_any_permissions?(:view_audit_logs)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.authorized?(:view_audit_logs)
        scope.all
      else
        scope.none
      end
    end
  end
end
