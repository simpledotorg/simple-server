class Api::V1::UserTransformer < Api::V2::UserTransformer
  class << self
    def to_response(user)
      Api::Current::Transformer.to_response(user)
        .merge(facility_ids: [user.registration_facility.id],
               'phone_number' => user.phone_number,
               'password_digest' => user.phone_number_authentication.password_digest)
        .except('otp', 'otp_valid_until', 'access_token', 'logged_in_at')
    end

    def from_request(user_params)
      Api::Current::Transformer.from_request(user_params)
        .merge(registration_facility_id: user_params[:facility_ids].first)
        .except(:facility_ids)
    end
  end
end