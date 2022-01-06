# frozen_string_literal: true

class Qa::PurgesController < APIController
  require "tasks/scripts/purge_users_data"

  skip_before_action :current_user_present?, only: [:purge_patient_data]
  skip_before_action :validate_sync_approval_status_allowed, only: [:purge_patient_data]
  skip_before_action :authenticate, only: [:purge_patient_data]
  skip_before_action :validate_facility, only: [:purge_patient_data]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:purge_patient_data]
  before_action :validate_access

  def purge_patient_data
    return unless FeatureToggle.enabled?("PURGE_ENDPOINT_FOR_QA")

    PurgeUsersData.perform
    head :ok
  end

  def validate_access
    purge_access_token = ENV["PURGE_URL_ACCESS_TOKEN"]
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, purge_access_token)
    end
  end
end
