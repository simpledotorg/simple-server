class Api::V1::UsersController < Api::V1::SyncController
  skip_before_action :authenticate

  def sync_from_user
    __sync_from_user__(users_params)
  end

  def sync_to_user
    __sync_to_user__('users')
  end

  private

  def merge_if_valid(user_params)
    validator = Api::V1::UserPayloadValidator.new(user_params)
    logger.debug "User had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/User/schema_invalid')
    else
      user = User.merge(Api::V1::Transformer.from_request(user_params))
    end

    { record:      user,
      errors_hash: (validator.errors_hash if validator.valid?) }
  end

  def find_records_to_sync(since, limit)
    User.updated_on_server_since(since, limit)
  end

  def transform_to_response(user)
    Api::V1::UserTransformer.to_response(user)
  end

  def users_params
    params.require(:users).map do |user_params|
      user_params.permit(
        :id,
        :created_at,
        :updated_at,
        :full_name,
        :phone_number,
        :password_digest,
        :facility_id
      )
    end
  end
end
