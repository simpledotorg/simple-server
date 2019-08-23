class InvitationPolicy < ApplicationPolicy
  def create?
    user_has_any_permissions?(
      :can_manage_all_users,
      [:can_manage_users_for_organization, record.organization]
    ) && user_can_invite_role(record.role)
  end

  def new?
    create?
  end

  private

  def user_can_invite_role(role)
    slugs = user.user_permissions.pluck(:permission_slug)
    roles_user_can_invite
      .slice(*slugs)
      .values
      .flat_map(&:itself)
      .include?(role.to_sym)
  end

  def roles_user_can_invite
    { can_manage_all_users: [:owner, :supervisor, :analyst, :organization_owner, :counsellor],
      can_manage_users_for_organization: [:supervisor, :analyst, :organization_owner, :counsellor] }
  end
end
