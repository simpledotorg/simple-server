class UserPermissionPolicy < ApplicationPolicy
  def create?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_manage_user_permissions
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def new?
    create?
  end

  def roles_user_can_invite
    if user.has_permission?(:can_manage_all_users)
      User.roles.except(:nurse)
    end
  end
end
