class Admin::OrganizationsController < AdminController
  before_action :set_organization, only: [:edit, :update, :destroy]

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  skip_after_action :verify_policy_scoped, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_authorization_attempted, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }

  def index
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.power_user? }
      @organizations = current_admin.accessible_organizations(:manage).order(:name)
    else
      authorize([:manage, Organization])
      @organizations = policy_scope([:manage, Organization]).order(:name)
    end
  end

  def new
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.power_user? }
      @organization = Organization.new
    else
      @organization = Organization.new
      authorize([:manage, @organization])
    end
  end

  def edit
  end

  def create
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.power_user? }
      @organization = Organization.new(organization_params)
    else
      @organization = Organization.new(organization_params)
      authorize([:manage, @organization])
    end

    if @organization.save
      redirect_to admin_organizations_url, notice: "Organization was successfully created."
    else
      render :new
    end
  end

  def update
    if @organization.update(organization_params)
      redirect_to admin_organizations_url, notice: "Organization was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @organization.destroy
    redirect_to admin_organizations_url, notice: "Organization was successfully deleted."
  end

  private

  def set_organization
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      @organization = authorize1 { current_admin.accessible_organizations(:manage).friendly.find(params[:id]) }
    else
      @organization = Organization.friendly.find(params[:id])
      authorize([:manage, @organization])
    end
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :description
    )
  end
end
