class AdminPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: :manage_admins)
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:manage_admins, nil],
      [:manage_admins, record.organization])
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:manage_admins)

      admin_scope = scope.joins(:email_authentications).where.not(email_authentications: { id: nil })
      required_permissions = user.user_permissions.where(permission_slug: :manage_admins)
      resources = required_permissions.map(&:resource).compact
      return admin_scope.all unless resources.present?

      admin_scope.where(organization: resources)
    end
  end
end
