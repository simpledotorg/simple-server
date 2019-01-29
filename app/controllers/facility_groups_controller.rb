class FacilityGroupsController < AdminController
  def show
    skip_authorization

    @users_requesting_approval = policy_scope(User).requested_sync_approval

    @organization = Organization.friendly.find(params[:organization_id])
    @facility_group = FacilityGroup.friendly.find(params[:id])

    Groupdate.time_zone = "New Delhi"

    @days_previous = 20
    @months_previous = 8

    @facilities = @facility_group.facilities
    @facility_group_analytics = Analytics::FacilityGroupDashboard.new(
      @facility_group,
      days_previous: @days_previous,
      months_previous: @months_previous
    )

    # Reset when done
    Groupdate.time_zone = "UTC"
  end

  private
end

