class ApprovalNotifierMailer < ApplicationMailer
  attr_reader :user

  def registration_approval_email(user_id:)
    @user = User.find(user_id)
    subject = I18n.t("registration_approval_email.subject",
      full_name: @user.full_name,
      org_name: @user.facility_group.organization.name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: organization_owner_emails,
         bcc: owner_emails)
  end

  def reset_password_approval_email(user_id:)
    @user = User.find(user_id)
    subject = I18n.t("reset_password_approval_email.subject", full_name: @user.full_name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: organization_owner_emails,
         bcc: owner_emails)
  end

  private

  # permissions_users are admins as per the old permissions system
  # accesses_users are admins as per the new permissions system
  # we need to send emails to the superset of the two till we flip everyone over to new permissions

  def supervisor_emails
    permissions_users = UserPermission.where(permission_slug: :approve_health_workers, resource: user.facility_group).map(&:user)
    accesses_users = User.admins.manager_access
      .select { |admin| admin.accessible_facilities(:manage).include?(user.facility) }
      .reject { |admin| admin.accesses.map(&:resource).include?(user.organization) }

    users = (permissions_users + accesses_users).uniq.compact
    users.map(&:email).join(",")
  end

  def organization_owner_emails
    permissions_users = UserPermission.where(permission_slug: :approve_health_workers, resource: user.organization).map(&:user)
    accesses_users = User.admins.manager_access
      .select { |admin| admin.accessible_organizations(:manage).where(id: user.organization).any? }

    users = (permissions_users + accesses_users).uniq.compact
    users.map(&:email).join(",")
  end

  def owner_emails
    permissions_users = UserPermission.where(permission_slug: :approve_health_workers, resource: nil).map(&:user)
    accesses_users = User.admins.power_user_access

    users = (permissions_users + accesses_users).uniq.compact
    users.map(&:email).join(",")
  end
end
