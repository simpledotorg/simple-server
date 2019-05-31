class AuditLogPolicy < ApplicationPolicy
  def index?
    user_has_any_permissions?(:can_manage_all_organizations)
  end

  def show?
    user_has_any_permissions?(:can_manage_all_organizations)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.authorized?(:can_manage_all_organizations)
        scope.all
      else
        scope.none
      end
    end
  end
end
