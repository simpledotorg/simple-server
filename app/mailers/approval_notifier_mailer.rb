class ApprovalNotifierMailer < ApplicationMailer
  default :from => 'help@simple.org'

  def supervisor_emails
    ENV['SUPERVISOR_EMAILS']
  end

  def owner_emails
    ENV['OWNER_EMAILS']
  end

  def registration_approval_email
    @user = params[:user]
    subject = I18n.t('registration_approval_email.subject', full_name: @user.full_name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: owner_emails)
  end

  def reset_password_approval_email
    @user = params[:user]
    subject = I18n.t('reset_password_approval_email.subject', full_name: @user.full_name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: owner_emails)
  end
end
