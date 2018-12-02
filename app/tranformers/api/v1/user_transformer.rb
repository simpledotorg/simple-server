class Api::V1::UserTransformer < Api::Current::UserTransformer
  class << self
    def to_response(user)
      Api::Current::Transformer.to_response(user)
        .merge(facility_ids: [user.facility.id])
        .except('otp', 'otp_valid_until', 'access_token', 'logged_in_at')
    end
  end
end