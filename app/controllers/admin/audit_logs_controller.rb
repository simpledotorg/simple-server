class Admin::AuditLogsController < AdminController
  before_action :set_audit_log, only: [:show]

  def index
    authorize AuditLog
    @audit_logs = []
    if params[:user_name].present?
      users = policy_scope(User).where('full_name ilike ?', "%#{params[:user_name]}%")
      @audit_logs = policy_scope(AuditLog).where(user_id: users.pluck(:id)).order(created_at: :desc)
    end
  end

  def show
  end

  private

  def set_audit_log
    @audit_log = AuditLog.find(params[:id])
    authorize @audit_log
  end
end
