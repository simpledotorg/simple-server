class Api::V4::UserTransformer < Api::V4::Transformer
  class << self
    def to_response(user)
       super
        .merge('registration_facility_id' => user.registration_facility.id,
               'phone_number' => user.phone_number,
               'password_digest' => user.phone_number_authentication.password_digest)
        .except('otp', 'otp_valid_until', 'access_token', 'logged_in_at', 'role', 'organization_id')
    end

    def to_find_response(user)
      to_response(user).slice('id', 'sync_approval_status')
    end
  end
end
