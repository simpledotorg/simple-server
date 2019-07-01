class UserPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_manage_all_organizations
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
   user.has_permission?(:can_manage_all_organizations)
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def disable_access?
    update?
  end

  def enable_access?
    update?
  end

  def reset_otp?
    update?
  end

  def create_user_for_invitation?
    update?
  end

  def new_user_for_invitation?
    create_user_for_invitation?
  end

  def assign_permissions?
    user.has_permission?(:can_manage_user_permissions)
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
