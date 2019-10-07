class AdminsController < AdminController
  before_action :set_admin, only: [:show, :edit, :update, :destroy]
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize User
    @admins = policy_scope(User.where.not(role: :nurse)).sort_by(&:email)
  end

  def show
  end

  def edit
  end

  def update
    User.transaction do
      binding.pry
      @admin.update!(user_params)
      next unless permission_params[:permissions].present?

      user.user_permissions.delete_all!
      permission_params[:permissions].each do |attributes|
        user.user_permissions.create!(attributes)
      end
    end
  end

  def destroy
    @admin.destroy
    redirect_to admins_url, notice: 'Admin was successfully deleted.'
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def set_admin
    @admin = User.find(params[:id])
    authorize @admin
  end

  def permission_params
    params.permit(permissions: [:permission_slug, :resource_type, :resource_id])
  end

  def user_params
    { full_name: params.require(:full_name),
      role: params.require(:role),
      organization_id: params.require(:organization_id),
      device_updated_at: Time.now }
  end
end
