class ApprovalNotifierMailer < ApplicationMailer
  attr_reader :user

  default from: 'help@simple.org'

  def registration_approval_email(user_id:)
    @user = User.find(user_id)
    subject = I18n.t('registration_approval_email.subject',
                     full_name: @user.full_name,
                     org_name: @user.facility_group.organization.name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: organization_owner_emails,
         bcc: owner_emails)
  end

  def reset_password_approval_email(user_id:)
    @user = User.find(user_id)
    subject = I18n.t('reset_password_approval_email.subject', full_name: @user.full_name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: organization_owner_emails,
         bcc: owner_emails)
  end

  private

  def supervisor_emails
    user.facility_group.admins.where(role: 'supervisor').pluck(:email).join(',')
  end

  def organization_owner_emails
    user.organization.admins.where(role: 'organization_owner').pluck(:email).join(',')
  end

  def owner_emails
    Admin.where(role: 'owner').pluck(:email).join(',')
  end
end
