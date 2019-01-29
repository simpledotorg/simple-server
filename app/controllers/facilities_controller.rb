class FacilitiesController < AdminController
  before_action :set_organization
  before_action :set_facility_group

  def show
    skip_authorization
    @facility = Facility.friendly.find(params[:id])
  end

  def graphics
    skip_authorization
    @facility = Facility.friendly.find(params[:facility_id])
  end

  private

  def set_facility_group
    @facility_group = FacilityGroup.friendly.find(params[:facility_group_id])
    # authorize(@facility_group)
  end

  def set_organization
    @organization = Organization.friendly.find(params[:organization_id])
    # authorize(@organization)
  end
end
