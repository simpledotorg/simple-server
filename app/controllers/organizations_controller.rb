class OrganizationsController < AdminController
  include Pagination

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  skip_after_action :verify_policy_scoped, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_authorization_attempted, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }

  def index
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      @accessible_facilities = current_admin.accessible_facilities(:view_reports)
      authorize1 { @accessible_facilities.any? }
    else
      authorize(:dashboard, :show?)
    end

    users = if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.accessible_users
    else
      policy_scope([:manage, :user, User])
    end

    @users_requesting_approval = paginate(users
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    @organizations =
      if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
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
