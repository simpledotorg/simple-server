module Api::V1::ApiControllerOverrides
  extend ActiveSupport::Concern
  included do
    def current_facility
      nil
    end

    def validate_facility
      true
    end
  end
end
