# frozen_string_literal: true

class DedupeIcddrbMedicalHistories2 < ActiveRecord::Migration[6.1]
  FACILITY_IDS = %w[
    4280917c-a10e-4125-bb79-5cf6ebe4bd2b
    75bdedd2-ca3a-483a-a81c-9f923d723489
    8207fda1-a37b-4c19-be25-6056c47e374b
    8a34af23-f0a4-46e1-8932-4b390b0bee64
    8c6840c6-9ce8-4e01-82ee-1b8af00675a2
    f472c5db-188f-4563-9bc7-9f86a6ed6403
    fdb34f45-923c-4612-aa15-3f8b6cc3175f
  ]

  def up
    unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
      return print "DedupeIcddrbMedicalHistories2 is only for production Bangladesh"
    end

    # NOTE: these merge resolution rules do not account for the case where the
    # attribute to merge is blank. Since we have verified that this blank edge
    # case does not occur in ICDDRB's data, we can get away with fewer rules.
    merge_resolution_rules = {
      Set["no"] => "no",
      Set["yes"] => "yes",
      Set["unknown"] => "unknown",
      Set["no", "yes"] => "yes",
      Set["no", "unknown"] => "no",
      Set["yes", "unknown"] => "yes",
      Set["yes", "no", "unknown"] => "yes"
    }

    fields_to_resolve = MedicalHistory.defined_enums.keys

    transaction do
      medical_histories_by_patient = MedicalHistory.joins(:patient)
        .where(patient: {assigned_facility_id: FACILITY_IDS})
        .group_by(&:patient_id)

      medical_histories_by_patient.each_value do |merge_candidates|
        next if merge_candidates.size < 2
        merged_med_history_attrs = merge_candidates.first&.attributes&.except("id")
        fields_to_resolve.each do |field_name|
          conflicting_values = merge_candidates.map(&field_name.to_sym).to_set
          merged_med_history_attrs[field_name] = merge_resolution_rules.fetch(conflicting_values)
        end
        MedicalHistory.create!(merged_med_history_attrs)
        merge_candidates.map(&:discard!)
      end
    end
  end

  def down
    puts "This migration cannot be reversed."
  end
end
