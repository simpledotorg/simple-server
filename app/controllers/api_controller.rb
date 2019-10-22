class APIController < ApplicationController
  before_action :current_user_present?,
                :validate_sync_approval_status_allowed,
                :authenticate,
                :validate_facility,
                :validate_current_facility_belongs_to_users_facility_group

  TIME_WITHOUT_TIMEZONE_FORMAT = '%FT%T.%3NZ'.freeze

  skip_before_action :verify_authenticity_token

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  private

  def current_user
    @current_user ||= User.find_by(id: request.headers['HTTP_X_USER_ID'])
  end

  def current_facility
    @current_facility ||= Facility.find_by(id: request.headers['HTTP_X_FACILITY_ID'])
  end

  def current_facility_group
    current_user.facility.facility_group
  end

  def current_timezone_offset
    request.headers['HTTP_X_TIMEZONE_OFFSET'] || 0
  end

  def validate_facility
    return head :bad_request unless current_facility.present?
  end

  def validate_current_facility_belongs_to_users_facility_group
    return head :unauthorized unless current_user.present? && current_facility_group.facilities.where(id: current_facility.id).present?
  end

  def current_user_present?
    return head :unauthorized unless current_user.present?
  end

  def validate_sync_approval_status_allowed
    head :forbidden unless current_user.sync_approval_status_allowed?
  end

  def authenticate
    return head :unauthorized unless access_token_authorized?
    current_user.mark_as_logged_in if current_user.has_never_logged_in?
  end

  def access_token_authorized?
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, current_user.access_token)
    end
  end

  def set_sentry_context
    Raven.user_context(
      id: request.headers['HTTP_X_USER_ID'],
      request_facility_id: request.headers['HTTP_X_FACILITY_ID']
    )
  end
end
