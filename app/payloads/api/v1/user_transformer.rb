module Api::V1::UserTransformer
  def self.to_response(user)
    Api::V1::Transformer.to_response(user)
      .except('otp', 'otp_valid_until')
  end
end