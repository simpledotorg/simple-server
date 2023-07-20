class Api::V4::ImportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :doorkeeper_authorize!
  before_action :validate_token_organization

  def import
    return head :not_found unless Flipper.enabled?(:imports_api)

    errors = JSON::Validator.fully_validate(
      Api::V4::Imports.schema_with_definitions,
      import_params.to_json
    )

    response = {errors: errors}
    return render json: response, status: :bad_request if errors.present?

    render json: response, status: :accepted
  end

  def import_params
    params.require(:resources)
  end

  def validate_token_organization
    token_organization = MachineUser.find_by(id: doorkeeper_token.application&.owner_id)&.organization_id
    unless token_organization.present? && token_organization == request.headers["HTTP_X_ORGANIZATION_ID"]
      head :forbidden
    end
  end
end
