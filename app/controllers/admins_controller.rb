class AdminsController < AdminController
  before_action :set_admin, only: [:show, :edit, :update, :destroy]
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :selectable_resource_types

  def index
    authorize User
    @admins = policy_scope(User.where.not(role: :nurse)).sort_by(&:email)
  end

  def show
  end

  def edit
  end

  def update
    @admin.resources = resource_gids
    user_permissions = @admin.resources.flat_map do |resource|
      @admin.default_permissions_for_resource_type(resource.class.to_s).map do |permission_slug|
        @admin.user_permissions.new(permission_slug: permission_slug, resource: resource)
      end
    end

    if @admin.update(admin_params.merge(user_permissions: user_permissions))
      redirect_to admin_path(@admin), notice: 'Admin was successfully updated.'
    else
      render :edit, notice: @admin.errors
    end
  end

  def destroy
    @admin.destroy
    redirect_to admins_url, notice: 'Admin was successfully deleted.'
  end

  private

  def selectable_resource_types
    User::DEFAULT_PERMISSIONS[@admin.role.to_sym]
      .map { |permission_slug| Permissions::ALL_PERMISSIONS[permission_slug][:resource_type] }
      .uniq
  end


  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def set_admin
    @admin = User.find(params[:id])
    authorize @admin
  end

  def resource_gids
    params.require(:admin).require(:resource_gids)
  end

  def admin_params
    params.require(:admin).permit(:full_name, :email)
  end
end
