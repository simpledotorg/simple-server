class Api::Current::FacilitiesController < Api::Current::SyncController
  skip_before_action :authenticate, only: [:sync_to_user]
  skip_before_action :validate_facility, only: [:sync_to_user]

  def sync_to_user
    __sync_to_user__('facilities')
  end

  private

  def transform_to_response(facility)
    Api::Current::FacilityTransformer.to_response(facility)
  end
end
