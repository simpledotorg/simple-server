class Api::V1::UsersController < APIController
  before_action :validate_registraion_payload, only: %i[create]

  def create
    user = User.create(user_from_request)
    return render json: { errors: user.errors }, status: :bad_request if user.invalid?
    render json: { user: user_to_response(user) }, status: :created
  end

  private

  def user_from_request
    Api::V1::Transformer.from_request(registration_params)
      .merge(sync_approval_status: 'waiting_for_approval')
  end

  def user_to_response(user)
    Api::V1::UserTransformer.to_response(user)
  end

  def validate_registraion_payload
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
        :facility_id,
        :updated_at,
        :created_at)
  end
end