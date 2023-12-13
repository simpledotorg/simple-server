class BulkApiImport::FhirConditionImporter
  include BulkApiImport::FhirImportable

  CONDITION_TRANSLATION = {
    "38341003" => :hypertension,
    "73211009" => :diabetes
  }.with_indifferent_access

  def initialize(resource:, organization_id:)
    @resource = resource
    @organization_id = organization_id
    @import_user = find_or_create_import_user(organization_id)
  end

  def import
    merge_result = build_attributes
      .then { Api::V3::MedicalHistoryTransformer.from_request(_1).merge(metadata) }
      .then { MedicalHistory.merge(_1) }

    AuditLog.merge_log(@import_user, merge_result) if merge_result.present?
    merge_result
  end

  def metadata
    {user_id: @import_user.id}
  end

  def build_attributes
    {
      id: translate_id(@resource.dig(:identifier, 0, :value), org_id: @organization_id),
      patient_id: translate_id(@resource[:subject][:identifier], org_id: @organization_id),
      prior_heart_attack: "unknown",
      prior_stroke: "unknown",
      chronic_kidney_disease: "unknown",
      receiving_treatment_for_hypertension: diagnoses[:hypertension],
      hypertension: diagnoses[:hypertension],
      diagnosed_with_hypertension: diagnoses[:hypertension],
      receiving_treatment_for_diabetes: diagnoses[:diabetes],
      diabetes: diagnoses[:diabetes],
      **timestamps
    }.compact.with_indifferent_access
  end

  def diagnoses
    @resource[:code][:coding].each_with_object({hypertension: "no", diabetes: "no"}) do |coding, diagnoses|
      condition = CONDITION_TRANSLATION[coding[:code]]
      diagnoses[condition] = "yes"
    end
  end
end
