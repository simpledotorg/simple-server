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

    unless Flipper.enabled?(:mock_imports_api)
      BulkApiImportJob.perform_later(resources: import_params) unless errors.present?
    end

    response = {errors: errors}
    return render json: response, status: :bad_request if errors.present?

    render json: response, status: :accepted
  end

  def import_params
    import_resources = params.require(:resources)
    import_resources.map do |import_resource|
      case import_resource[:resourceType]
      when "Patient"
        permit_patient_resource(import_resource)
      when "Appointment"
        permit_appointment_resource(import_resource)
      when "Observation"
        permit_observation_resource(import_resource)
      else
        next
      end
    end
  end

  def permit_patient_resource(resource)
    resource.permit(
      :resourceType,
      :gender,
      :birthDate,
      :deceasedBoolean,
      :telecom,
      :name,
      :active,
      meta: [:lastUpdated, :createdAt],
      identifier: [:value],
      managingOrganization: [:value],
      registrationOrganization: [:value],
      address: [:line, :district, :city, :postalCode]
    )
  end

  def permit_appointment_resource(resource)
    resource.permit(
      :resourceType,
      :status,
      :start,
      meta: [:lastUpdated, :createdAt],
      identifier: [:value],
      appointmentOrganization: [:identifier],
      participant: [
        actor: [:identifier]
      ]
    )
  end

  def permit_observation_resource(resource)
    resource.permit(
      :resourceType,
      :effectiveDateTime,
      meta: [:lastUpdated, :createdAt],
      identifier: [:value],
      subject: [:identifier],
      performer: [:identifier],
      code: {coding: [:system, :code]},
      component: [{
        code: {coding: [:system, :code]},
        valueQuantity: [:value, :unit, :system, :code]
      }]
    )
  end

  def validate_token_organization
    token_organization = MachineUser.find_by(id: doorkeeper_token.application&.owner_id)&.organization_id
    unless token_organization.present? && token_organization == request.headers["HTTP_X_ORGANIZATION_ID"]
      head :forbidden
    end
  end
end
