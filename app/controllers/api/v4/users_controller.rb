class Api::V4::UsersController < APIController
  skip_before_action :current_user_present?, only: [:activate]
  skip_before_action :validate_sync_approval_status_allowed, only: [:activate]
  skip_before_action :authenticate, only: [:activate]
  skip_before_action :validate_facility, only: [:activate]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:activate]

  def activate
    return head :bad_request unless activate_params.present?

    user = User.find(request_user_id)
    return head :not_found unless user.present?

    phone_number_authentication = user.phone_number_authentication
    phone_number_authentication.set_otp
    phone_number_authentication.save

    unless FeatureToggle.auto_approve_for_qa?
      SmsNotificationService
        .new(user.phone_number, ENV['TWILIO_PHONE_NUMBER'])
        .send_request_otp_sms(user.otp)
    end

    render json: user_to_response(user), status: 200
  end

  private

  def request_user_id
    params.require(:id)
  end

  def user_to_response(user)
    Api::V4::UserTransformer.to_response(user)
  end
end
