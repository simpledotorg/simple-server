# frozen_string_literal: true

class Api::V4::StatesController < APIController
  skip_before_action :current_user_present?, only: [:index]
  skip_before_action :validate_sync_approval_status_allowed, only: [:index]
  skip_before_action :authenticate, only: [:index]
  skip_before_action :validate_facility, only: [:index]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:index]

  def index
    state_names = Region.facility_regions
      .joins("inner join regions states ON states.path @> regions.path and states.region_type = 'state'")
      .distinct("states.name")
      .pluck("states.name")

    render json: {states: state_names.map { |state| {name: state} }}
  end
end
