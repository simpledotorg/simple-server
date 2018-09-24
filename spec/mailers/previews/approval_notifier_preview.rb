# Preview all emails at http://localhost:3000/rails/mailers/approval_notifier
class ApprovalNotifierPreview < ActionMailer::Preview
  def registration_approval_email
    ApprovalNotifierMailer.with(user: User.first).registration_approval_email
  end

  def reset_password_approval_email
    ApprovalNotifierMailer.with(user: User.first).reset_password_approval_email
  end
end
