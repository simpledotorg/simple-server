class Api::Current::UserTransformer
  class << self
    def to_response(user)
      Api::Current::Transformer.to_response(user)
        .merge('registration_facility_id' => user.registration_facility.id,
               'phone_number' => user.phone_number,
               'password_digest' => user.phone_number_authentication.password_digest)
        .except('sync_approval_status', 'sync_approval_status_reason', 'otp', 'otp_valid_until', 'access_token', 'logged_in_at')
    end
  end
end