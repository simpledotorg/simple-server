class AdminsController < AdminController
  before_action :set_admin, only: [:show, :edit, :update, :destroy]
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Admin
    @admins = policy_scope(Admin).order(:email)
  end

  def show
  end

  def edit
  end

  def update
    admin_access_controls = access_controllable_ids.reject(&:empty?).map do |access_controllable_id|
      AdminAccessControl.new(
        access_controllable_type: access_controllable_type,
        access_controllable_id: access_controllable_id)
    end
    if @admin.update(admin_params.merge(admin_access_controls: admin_access_controls))
      redirect_to @admin, notice: 'Admin was successfully updated.'
    else
      render :edit
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
    @admin = Admin.find(params[:id])
    authorize @admin
  end

  def access_controllable_ids
    params.require(:admin).require(:access_controllable_ids)
  end

  def access_controllable_type
    params.require(:admin).require(:access_controllable_type)
  end

  def admin_params
    params.require(:admin).permit(:email)
  end
end
