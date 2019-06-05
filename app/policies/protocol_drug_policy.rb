class ProtocolDrugPolicy < ApplicationPolicy
  def index?
    user_has_any_permissions?(:can_manage_all_protocols)
  end

  def show?
    user_has_any_permissions?(:can_manage_all_protocols)
  end

  def create?
    user_has_any_permissions?(:can_manage_all_protocols)
  end

  def new?
    create?
  end

  def update?
    user_has_any_permissions?(:can_manage_all_protocols)
  end

  def edit?
    update?
  end

  def destroy?
    user_has_any_permissions?(:can_manage_all_protocols)
  end

  private

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:can_manage_all_protocols)
        scope.all
      else
        scope.none
      end
    end
  end
end
