class ApprovalNotifierMailer < ApplicationMailer
  attr_reader :user

  default from: 'help@simple.org'

  def registration_approval_email
    @user = params[:user]
    subject = I18n.t('registration_approval_email.subject',
                     full_name: @user.full_name,
                     org_name: @user.facility_group.organization.name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: organization_owner_emails,
         bcc: owner_emails)
  end

  def reset_password_approval_email
    @user = params[:user]
    subject = I18n.t('reset_password_approval_email.subject', full_name: @user.full_name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: organization_owner_emails,
         bcc: owner_emails)
  end

  private

  def supervisor_emails
    UserPermission
      .where(permission_slug: :can_manage_users_for_facility_group, resource: user.facility_group)
      .map { |permission| permission.user.email }
      .join(',')
  end

  def organization_owner_emails
    UserPermission
      .where(permission_slug: :can_manage_users_for_organization, resource: user.organization)
      .map { |permission| permission.user.email }
      .join(',')
  end

  def owner_emails
    UserPermission
      .where(permission_slug: :can_manage_all_users)
      .map { |permission| permission.user.email }
      .join(',')
  end
end
