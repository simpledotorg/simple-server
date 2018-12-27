class AdminsController < AdminController
  before_action :set_admin, only: [:show, :edit, :update, :destroy]

  def index
    authorize Admin
    @admins = Admin.all.order(:email)
  end

  def show
  end

  def edit
  end

  def update
    admin_access_controls = access_controllable_ids.reject(&:empty?).map do |access_controllable_id|
      AdminAccessControl.new(
        admin_id: @admin.id,
        access_controllable_type: access_controllable_type,
        access_controllable_id: access_controllable_id)
    end
    @admin.admin_access_controls = admin_access_controls
    @admin.save
    if @admin.update(admin_params)
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
