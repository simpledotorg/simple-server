class MyFacilitiesController < AdminController
  include Pagination

  def index
    authorize(:dashboard, :show?)

    @users_requesting_approval = policy_scope([:manage, :user, User])
                                   .requested_sync_approval
                                   .order(updated_at: :desc)

    @users_requesting_approval = paginate(@users_requesting_approval)

    @facilities = policy_scope([:manage, :facility, Facility])
    @active_facilities = MyFacilitiesQuery.new(@facilities).active_facilities
  end
end
