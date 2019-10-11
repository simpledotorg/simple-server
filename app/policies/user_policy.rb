class UserPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: :approve_health_workers)
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:approve_health_workers, nil],
      [:approve_health_workers, record.organization],
      [:approve_health_workers, record.facility_group])
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
    user_has_any_permissions?(
      [:manage_admins, nil],
      [:manage_admins, user.organization])
  end

  def new_user_for_invitation?
    create_user_for_invitation?
  end

  def index_admins?
    create_user_for_invitation?
  end

  def assign_permissions?
    user.has_permission?(:manage_admins)
  end

  def destroy?
    user_has_any_permissions?(
      [:approve_health_workers, nil],
      [:approve_health_workers, record.organization],
      [:approve_health_workers, record.facility_group])
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      required_permissions = user.user_permissions.where(permission_slug: :approve_health_workers)
      return scope.none unless required_permissions.present?

      resources = required_permissions.map(&:resource).compact
      return scope.all unless resources.present?

      facilities = resources.flat_map(&:facilities)
      scope.joins(:phone_number_authentications).where(phone_number_authentications: { facility: facilities })
    end
  end
end
