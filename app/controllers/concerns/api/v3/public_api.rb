# frozen_string_literal: true

module Api::V3::PublicApi
  extend ActiveSupport::Concern
  included do
    # Skips auth actions for API endpoints that are meant to be publicly accessible without authentication
    # eg: facilities, protocols, drugs
    skip_before_action :current_user_present?, only: [:sync_to_user]
    skip_before_action :validate_sync_approval_status_allowed, only: [:sync_to_user]
    skip_before_action :authenticate, only: [:sync_to_user]
    skip_before_action :validate_facility, only: [:sync_to_user]
    skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:sync_to_user]
  end
end
