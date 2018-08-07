# Preview all emails at http://localhost:3000/rails/mailers/approval_notifier
class ApprovalNotifierPreview < ActionMailer::Preview
  def approval_email
    ApprovalNotifierMailer.with(user: User.first).approval_email
  end
end
