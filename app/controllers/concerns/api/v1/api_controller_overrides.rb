module Api::V1::ApiControllerOverrides
  extend ActiveSupport::Concern
  included do
    def validate_facility
      true
    end

    def validate_current_facility_belongs_to_users_facility_group
      true
    end
  end
end
