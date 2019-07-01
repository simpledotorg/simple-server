class Admin::UserPermissionsController < AdminController
  before_action :set_user

  def index
    authorize @user, :show?
    @user_permissions = policy_scope(@user.user_permissions)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
