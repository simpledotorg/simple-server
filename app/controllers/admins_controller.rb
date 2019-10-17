class AdminsController < AdminController
  before_action :set_admin, only: [:show, :edit, :update, :destroy]
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize User, :index_admins?
    @admins = policy_scope(User.where.not(role: :nurse)).sort_by(&:email)
  end

  def show
  end

  def edit
  end

  def update
    User.transaction do
      @admin.update!(user_params)
      next unless permission_params.present?

      @admin.user_permissions.delete_all
      permission_params.each do |attributes|
        @admin.user_permissions.create!(attributes.permit(
          :permission_slug,
          :resource_id,
          :resource_type))
      end
    end
    render json: {}, status: :accepted
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
    params.require(:permissions)
  end

  def user_params
    { full_name: params.require(:full_name),
      role: params.require(:role),
      organization_id: params[:organization_id],
      device_updated_at: Time.current }
  end
end
