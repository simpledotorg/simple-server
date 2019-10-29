class Manage::Admin::UserPolicy < ApplicationPolicy

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

  def create?
    user_has_any_permissions?(
      [:manage_admins, nil],
      [:manage_admins, record.organization])
  end

  def new?
    user.has_permission?(:manage_admins)
  end

  def update?
    create?
  end

  def edit?
    edit_admin?(record)
  end

  def destroy?
    destroy_admin?(record)
  end

  def edit_admin?(record)
    user_has_any_permissions?(
      [:manage_admins, nil],
      [:manage_admins, record.organization])
  end

  def destroy_admin?(record)
    edit_admin?(record)
  end

  def allowed_access_levels
    Permissions::ACCESS_LEVELS.select { |al| (al[:default_permissions] - user_permissions).blank? }
  end

  def allowed_permissions
    Permissions::ALL_PERMISSIONS.select { |k, v| user_permissions.include?(k) }.values
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

  private

  def user_permissions
    user.user_permissions.pluck(:permission_slug).map(&:to_sym)
  end
end
