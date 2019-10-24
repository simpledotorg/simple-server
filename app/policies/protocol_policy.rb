class ProtocolPolicy < ApplicationPolicy
  def index?
    user_has_any_permissions?(:manage_protocols)
  end

  def show?
    index?
  end

  def create?
    user_has_any_permissions?(:manage_protocols)
  end

  def new?
    create?
  end

  def update?
    user_has_any_permissions?(:manage_protocols)
  end

  def edit?
    update?
  end

  def destroy?
    user_has_any_permissions?(:manage_protocols)
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:manage_protocols)
        scope.all
      else
        scope.none
      end
    end
  end
end
