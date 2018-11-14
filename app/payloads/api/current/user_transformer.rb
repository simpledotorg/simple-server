module Api::Current::UserTransformer
  def self.to_response(user)
    Api::Current::Transformer.to_response(user)
      .merge(facility_ids: user.facilities.map(&:id))
      .except('otp', 'otp_valid_until', 'access_token', 'logged_in_at')
  end
end