class Api::V1::PrescriptionDrugsController < Api::V1::SyncController
  def sync_from_user
    __sync_from_user__(prescription_drugs_params)
  end

  def sync_to_user
    __sync_to_user__('prescription_drugs')
  end

  private

  def merge_if_valid(prescription_drug_params)
    validator = Api::V1::PrescriptionDrugPayloadValidator.new(prescription_drug_params)
    logger.debug "Prescription Drug had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/PrescriptionDrug/schema_invalid')
    else
      PrescriptionDrug.merge(Api::V1::Transformer.from_request(prescription_drug_params))
    end

    validator.errors_hash if validator.invalid?
  end

  def find_records_to_sync(since, limit)
    PrescriptionDrug.updated_on_server_since(since, limit)
  end

  def transform_to_response(prescription_drug)
    Api::V1::Transformer.to_response(prescription_drug)
  end

  def prescription_drugs_params
    params.require(:prescription_drugs).map do |prescription_drug_params|
      prescription_drug_params.permit(
        :id,
        :name,
        :dosage,
        :rxnorm_code,
        :is_protocol_drug,
        :is_deleted,
        :patient_id,
        :facility_id,
        :created_at,
        :updated_at
      )
    end
  end
end
