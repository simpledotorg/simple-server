module Api::Current::ValidateModel
  extend ActiveSupport::Concern
  included do
    before_action :validate_model, only: [:sync_from_user]

    def record_errors(params)
      model_class = controller_name.classify.constantize
      record = model_class.new(params)
      return if record.valid?

      record.errors.full_messages
    end

    def validate_model
      errors = request_params.map do |params|
        err = record_errors(transform_from_request(params))
        { id: params['id'], errors: err } if err.present?
      end.compact

      return if errors.blank?

      render json: { errors: errors }, status: 200
    end
  end
end
