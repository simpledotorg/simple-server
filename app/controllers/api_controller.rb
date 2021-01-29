class APIController < ApplicationController
  before_action :current_user_present?
  before_action :validate_sync_approval_status_allowed
  before_action :authenticate
  before_action :validate_facility
  before_action :validate_current_facility_belongs_to_users_facility_group

  TIME_WITHOUT_TIMEZONE_FORMAT = "%FT%T.%3NZ".freeze

  skip_before_action :verify_authenticity_token

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  private

  def current_user
    @current_user ||= User.find_by(id: request.headers["HTTP_X_USER_ID"])
  end

  def current_facility
    @current_facility ||= Facility.find_by(id: request.headers["HTTP_X_FACILITY_ID"])
  end

  def current_facility_group
    current_user.facility.facility_group
  end

  def current_sync_region
    # This method selectively permits only FacilityGroup sync (via facility group ID)
    # and block-level sync (via regions) and offers facility group as a safe fallback.
    # Over time, the facility group ID support can be dropped and this method can
    # allow other region types as well
    return current_facility_group if requested_sync_region_id.blank?
    return current_facility_group if requested_sync_region_id == current_facility_group.id
    return current_block if block_level_sync?

    current_facility_group
  end

  def block_level_sync?
    current_user.block_level_sync? && requested_sync_region_id == current_block.id
  end

  def current_block
    # Fetching current block from current_facility is safer
    # than fetching it by Region.find(requested_sync_region_id)
    # since the requested_sync_region_id can be an FG id.
    # This can be replaced in the future when facility group ID support is dropped.
    current_facility.region.block_region
  end

  def current_timezone_offset
    request.headers["HTTP_X_TIMEZONE_OFFSET"].to_i || 0
  end

  def resync_token
    request.headers["HTTP_X_RESYNC_TOKEN"]
  end

  def requested_sync_region_id
    request.headers["HTTP_X_SYNC_REGION_ID"]
  end

  def validate_facility
    head :bad_request unless current_facility.present?
  end

  def validate_current_facility_belongs_to_users_facility_group
    head :unauthorized unless current_user.present? &&
      current_facility_group.facilities.where(id: current_facility.id).present?
  end

  def current_user_present?
    head :unauthorized unless current_user.present?
  end

  def validate_sync_approval_status_allowed
    head :forbidden unless current_user.sync_approval_status_allowed?
  end

  def authenticate
    return head :unauthorized unless access_token_authorized?
    RequestStore.store[:current_user_id] = current_user.id
    current_user.mark_as_logged_in if current_user.has_never_logged_in?
  end

  def access_token_authorized?
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, current_user.access_token)
    end
  end

  def set_sentry_context
    Sentry.set_user(
      id: request.headers["HTTP_X_USER_ID"],
      request_facility_id: request.headers["HTTP_X_FACILITY_ID"]
    )
  end
end
