class InvitationPolicy < Struct.new(:user, :invitaion)
  def create?
    user.owner? || user.organization_owner?
  end

  def new?
    create?
  end

  def invite_owner?
    user.owner?
  end

  def invite_organization_owner?
    user.owner? || user.organization_owner?
  end

  def invite_supervisor?
    user.owner? || user.organization_owner?
  end

  def invite_analyst?
    user.owner? || user.organization_owner?
  end

  def invite_counsellor?
    user.owner? || user.organization_owner?
  end
end
