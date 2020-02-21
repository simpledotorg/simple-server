module Api::Current::ValidateSchema
  extend ActiveSupport::Concern
  included do
    before_action :validate_schema, only: [:sync_from_user]

    def validator_class_name
      "Api::Current::#{controller_name.classify}PayloadValidator"
    end

    def request_key
      controller_name
    end

    def validate_schema
      validator = validator_class_name.constantize.new(request_key => request_params)
      binding.pry
      return if validator.valid?

      render json: { errors: validator.errors }, status: 200
    end
  end
end
