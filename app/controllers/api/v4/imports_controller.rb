class Api::V4::ImportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :doorkeeper_authorize!
  before_action :validate_token_organization

  rescue_from ActionController::ParameterMissing do |error|
    log_failure(error)
    render json: {error: "Unable to find key in payload: \"#{error.param}\""}, status: :bad_request
  end

  def import
    return head :not_found unless Flipper.enabled?(:imports_api)

    errors = BulkApiImport::Validator.new(organization: organization_id, resources: import_params).validate

    unless Flipper.enabled?(:mock_imports_api)
      BulkApiImportJob.perform_later(resources: import_params, organization_id: organization_id) unless errors.present?
    end

    response = {errors: errors}
    if errors.present?
      log_failure(errors)
      return render json: response, status: :bad_request
    end

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
      when "MedicationRequest"
        permit_medication_request_resource(import_resource)
      when "Condition"
        permit_condition_resource(import_resource)
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
      :active,
      name: [:text],
      meta: [:lastUpdated, :createdAt],
      identifier: [:value],
      managingOrganization: [:value],
      registrationOrganization: [:value],
      address: [:district, :city, :postalCode, line: []]
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
      appointmentCreationOrganization: [:identifier],
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

  def permit_medication_request_resource(resource)
    resource.permit(
      :resourceType,
      medicationReference: [:reference],
      meta: [:lastUpdated, :createdAt],
      identifier: [:value],
      subject: [:identifier],
      performer: [:identifier],
      dispenseRequest: {expectedSupplyDuration: [:value, :unit, :system, :code]},
      dosageInstruction: [
        [
          {
            timing: [:code],
            doseAndRate: [{
              doseQuantity: [:value, :unit, :system, :code]
            }]
          },
          :text
        ]
      ],
      contained: [
        [
          :resourceType,
          :id,
          :status,
          {code: {coding: [:system, :code, :display]}}
        ]
      ]
    )
  end

  def permit_condition_resource(resource)
    resource.permit(
      :resourceType,
      meta: [:lastUpdated, :createdAt],
      identifier: [:value],
      subject: [:identifier],
      code: {coding: [:system, :code]}
    )
  end

  def validate_token_organization
    token_organization = MachineUser.find_by(id: doorkeeper_token.application&.owner_id)&.organization_id
    unless token_organization.present? && token_organization == organization_id
      log_failure(error: "invalid organization in token")
      head :forbidden
    end
  end

  def organization_id
    request.headers["HTTP_X_ORGANIZATION_ID"]
  end

  def log_failure(errors)
    Rails.logger.info(
      msg: "import_api_error",
      controller: self.class.name,
      action: action_name,
      organization_id: organization_id,
      errors: errors
    )
  end
end
