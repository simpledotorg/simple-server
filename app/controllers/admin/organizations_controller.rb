# frozen_string_literal: true

class Admin::OrganizationsController < AdminController
  before_action :set_organization, only: [:edit, :update, :destroy]

  def index
    authorize { current_admin.accessible_organizations(:manage).any? }
    @organizations = current_admin.accessible_organizations(:manage).order(:name)
  end

  def new
    authorize { current_admin.power_user? }
    @organization = Organization.new
  end

  def edit
  end

  def create
    authorize { current_admin.power_user? }
    @organization = Organization.new(organization_params)

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
    if @organization.discardable?
      @organization.discard
      redirect_to admin_organizations_url, notice: "Organization was successfully deleted."
    else
      redirect_to admin_facilities_url, notice: "Organization cannot be deleted, please delete Facility Groups and try again."
    end
  end

  private

  def set_organization
    @organization = authorize { current_admin.accessible_organizations(:manage).friendly.find(params[:id]) }
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :description
    )
  end
end
