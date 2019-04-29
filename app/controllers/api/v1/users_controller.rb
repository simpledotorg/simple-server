class Api::V1::UsersController < Api::V2::UsersController
  include Api::V1::ApiControllerOverrides

  def user_from_request
    Api::V1::UserTransformer.from_request(registration_params)
  end

  def user_to_response(user)
    Api::V1::UserTransformer.to_response(user)
  end

  def validate_registration_payload
    validator = Api::V1::UserRegistrationPayloadValidator.new(registration_params)
    logger.debug "User registration params had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      render json: { errors: validator.errors }, status: :bad_request
    end
  end

  def registration_params
    params.require(:user)
      .permit(
        :id,
        :full_name,
        :phone_number,
        :password_digest,
        :updated_at,
        :created_at,
        facility_ids: [])
  end
end
