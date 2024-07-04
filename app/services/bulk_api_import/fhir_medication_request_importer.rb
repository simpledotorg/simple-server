class BulkApiImport::FhirMedicationRequestImporter
  include BulkApiImport::FhirImportable

  FREQUENCY_TRANSLATION = {
    QD: :OD,
    BID: :BD,
    TID: :TDS,
    QID: :QDS
  }.with_indifferent_access

  MEDICATION_STATUS_MAPPING = {
    "active" => :active,
    "inactive" => :inactive,
    "entered-in-error" => :inactive
  }

  def initialize(resource:, organization_id:)
    @resource = resource
    @organization_id = organization_id
    @import_user = find_or_create_import_user(organization_id)
  end

  def import
    merge_result = build_attributes
      .then { Api::V3::PrescriptionDrugTransformer.from_request(_1).merge(metadata) }
      .then { PrescriptionDrug.merge(_1) }

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
      facility_id: translate_facility_id(@resource[:performer][:identifier], org_id: @organization_id),
      is_protocol_drug: false,
      name: contained_medication[:code][:coding][0][:display],
      rxnorm_code: contained_medication[:code][:coding][0][:code],
      frequency: frequency,
      dosage: dosage,
      is_deleted: drug_deleted?,
      **timestamps
    }.compact.with_indifferent_access
  end

  def contained_medication
    @resource[:contained][0]
  end

  def frequency
    @resource.dig(:dosageInstruction, 0, :timing, :code).then { |code| FREQUENCY_TRANSLATION[code] }
  end

  def dosage
    dose_quantity = @resource.dig(:dosageInstruction, 0, :doseAndRate, 0, :doseQuantity)
    if dose_quantity
      "#{dose_quantity[:value]} #{dose_quantity[:unit]}"
    else
      @resource.dig(:dosageInstruction, 0, :text)
    end
  end

  def drug_deleted?
    MEDICATION_STATUS_MAPPING[contained_medication[:status]] == :inactive
  end
end
