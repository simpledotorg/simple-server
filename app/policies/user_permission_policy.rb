class UserPermissionPolicy < ApplicationPolicy
  def create?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:manage_admins_for_organization
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def new?
    create?
  end

  def roles_user_can_invite
    if user.has_permission?(:manage_admins_for_all_organizations)
      User.roles.except(:nurse)
    end
  end
end
