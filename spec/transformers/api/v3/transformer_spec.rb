# frozen_string_literal: true

require "rails_helper"

def dedupe(old_record, new_record, user)
  DeduplicationLog.create!(
    user_id: user.id,
    record_type: old_record.class.to_s,
    deleted_record_id: old_record.id,
    deduped_record_id: new_record.id
  )
  old_record.discard
end

RSpec.describe Api::V3::Transformer do
  context "redirects to deduped records if present" do
    it "doesn't do anything if the record is not deduped" do
      bp = create(:blood_pressure)
      transformed_attrs = Api::V3::Transformer.from_request(build_blood_pressure_payload(bp))
      expect(transformed_attrs["id"]).to eq bp.id
      expect(transformed_attrs["patient_id"]).to eq bp.patient.id
    end

    it "changes the id and patient id to the deduped records" do
      admin = create(:admin)
      deleted_bp = create(:blood_pressure, user: admin)
      deduped_bp = create(:blood_pressure, user: admin)

      dedupe(deleted_bp, deduped_bp, admin)
      dedupe(deleted_bp.patient, deduped_bp.patient, admin)

      transformed_attrs = Api::V3::Transformer.from_request(updated_blood_pressure_payload(deleted_bp))
      expect(transformed_attrs["id"]).to eq deduped_bp.id
      expect(transformed_attrs["patient_id"]).to eq deduped_bp.patient_id
    end

    it "does not changes the patient id if is not present" do
      admin = create(:admin)
      deleted_patient = create(:patient, registration_user: admin)
      deduped_patient = create(:patient, registration_user: admin)

      dedupe(deleted_patient, deduped_patient, admin)

      transformed_attrs = Api::V3::Transformer.from_request(updated_patient_payload(deleted_patient))
      expect(transformed_attrs["id"]).to eq deduped_patient.id
    end

    it "sets the patient id if the record is new but patient is deduped" do
      admin = create(:admin)
      deleted_patient = create(:patient, registration_user: admin)
      new_bp = create(:blood_pressure, patient: deleted_patient, user: admin)
      deduped_patient = create(:patient, registration_user: admin)

      dedupe(deleted_patient, deduped_patient, admin)
      transformed_attrs = Api::V3::Transformer.from_request(build_blood_pressure_payload(new_bp))
      expect(transformed_attrs["id"]).to eq new_bp.id
      expect(transformed_attrs["patient_id"]).to eq deduped_patient.id
    end
  end
end
