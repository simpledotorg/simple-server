# frozen_string_literal: true

class Api::V3::HelpController < APIController
  layout false

  skip_before_action :current_user_present?, only: [:show]
  skip_before_action :validate_sync_approval_status_allowed, only: [:show]
  skip_before_action :authenticate, only: [:show]
  skip_before_action :validate_facility, only: [:show]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:show]

  def show
  end
end
