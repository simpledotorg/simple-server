class OrganizationsController < AdminController
  include Pagination

  skip_after_action :verify_authorized, if: -> { current_admin.permissions_v2_enabled? }
  skip_after_action :verify_policy_scoped, if: -> { current_admin.permissions_v2_enabled? }
  after_action :verify_authorization_attempted, if: -> { current_admin.permissions_v2_enabled? }

  def index
    if current_admin.permissions_v2_enabled?
      @accessible_facilities = current_admin.accessible_facilities(:view_reports)
      authorize_v2 { @accessible_facilities.any? }
    else
      authorize(:dashboard, :show?)
    end

    users = if current_admin.permissions_v2_enabled?
      current_admin.accessible_users(:manage)
    else
      policy_scope([:manage, :user, User])
    end

    @users_requesting_approval = users
      .requested_sync_approval
      .order(updated_at: :desc)

    @users_requesting_approval = paginate(users
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    @organizations =
      if current_admin.permissions_v2_enabled?
        @accessible_facilities
          .includes(facility_group: :organization)
          .flat_map(&:organization)
          .uniq
          .compact
          .sort_by(&:name)
      else
        policy_scope([:cohort_report, Organization]).order(:name)
      end
  end
end
