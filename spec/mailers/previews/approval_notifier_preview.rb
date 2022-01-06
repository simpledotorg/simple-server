# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/approval_notifier
class ApprovalNotifierPreview < ActionMailer::Preview
  def registration_approval_email
    user = User.non_admins.lazy.select { |user| user.facility.present? }.first
    ApprovalNotifierMailer.with(user: user).registration_approval_email(user_id: user.id)
  end

  def reset_password_approval_email
    user = User.non_admins.lazy.select { |user| user.facility.present? }.first
    ApprovalNotifierMailer.with(user: user).reset_password_approval_email(user_id: user.id)
  end
end
