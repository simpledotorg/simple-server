class InvitationPolicy < Struct.new(:user, :invitaion)
  def create?
    user.has_permission?(:can_manage_all_users)
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
