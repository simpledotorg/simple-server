class BulkApiImport::FhirConditionImporter
  include BulkApiImport::FhirImportable

  CONDITION_TRANSLATION = {
    "38341003" => :hypertension,
    "73211009 " => :diabetes
  }.with_indifferent_access

  def initialize(condition_resource)
    @resource = condition_resource
  end

  def import
    merge_result = build_attributes
      .then { Api::V3::PrescriptionDrugTransformer.from_request(_1).merge(metadata) }
      .then { PrescriptionDrug.merge(_1) }

    AuditLog.merge_log(import_user, merge_result) if merge_result.present?
    merge_result
  end

  def metadata
    {user_id: import_user.id}
  end

  def build_attributes
    {
      id: translate_id(@resource.dig(:identifier, 0, :value)),
      patient_id: translate_id(@resource[:subject][:identifier]),
      facility_id: translate_facility_id(@resource[:performer][:identifier]),
      is_protocol_drug: false,
      name: contained_medication[:code][:coding][0][:display],
      rxnorm_code: contained_medication[:code][:coding][0][:code],
      frequency: frequency,
      duration_in_days: @resource.dig(:dispenseRequest, :expectedSupplyDuration, :value),
      dosage: dosage,
      is_deleted: false,
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
end
