# frozen_string_literal: true

class ApprovalNotifierMailer < ApplicationMailer
  attr_reader :user

  def registration_approval_email(user_id:)
    if SIMPLE_SERVER_ENV == "production"
      @user = User.find(user_id)
      subject = I18n.t("registration_approval_email.subject",
        full_name: @user.full_name,
        org_name: @user.facility_group.organization.name)
      mail(subject: subject,
        to: supervisor_emails,
        cc: organization_owner_emails,
        bcc: owner_emails)
    else
      Rails.logger.info "Non-production environment: skipped sending registration_approval_email"
    end
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

  def supervisor_emails
    User.admins.manager_access
      .where(receive_approval_notifications: true)
      .select { |admin| admin.accessible_facilities(:manage).include?(user.facility) }
      .reject { |admin| admin.accesses.map(&:resource).include?(user.organization) }
      .map(&:email)
      .join(",")
  end

  def organization_owner_emails
    User.admins.manager_access
      .where(receive_approval_notifications: true)
      .select { |admin| admin.accessible_organizations(:manage).where(id: user.organization).any? }
      .map(&:email)
      .join(",")
  end

  def owner_emails
    User.admins.power_user_access
      .where(receive_approval_notifications: true)
      .map(&:email)
      .join(",")
  end
end
