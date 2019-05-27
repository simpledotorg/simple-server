class Api::Current::UserTransformer
  class << self
    def to_response(user)
      Api::Current::Transformer.to_response(user)
        .merge('registration_facility_id' => user.registration_facility.id)
        .except('otp', 'otp_valid_until', 'access_token', 'logged_in_at')
    end
  end
end