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

    def admin_params
      params.require(:admin).permit(:email, :role, facility_group_ids: [])
    end
end
