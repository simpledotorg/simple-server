class Api::V4::UserTransformer < Api::V4::Transformer
  class << self
    def to_find_response(user)
      to_response(user).slice('id', 'sync_approval_status')
    end
  end
end
