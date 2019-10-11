class UserPermissionPolicy < ApplicationPolicy
  def create?
    user_has_any_permissions?(
      [:manage_admins, nil],
      [:manage_admins, record.facility.organization],
      [:manage_admins, record.facility.facility_group],
    )
  end

  def new?
    create?
  end

  def roles_user_can_invite
    if user.has_permission?(:manage_admins)
      User.roles.except(:nurse)
    end
  end
end
