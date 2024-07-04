# frozen_string_literal: true

class DedupeIcddrbMedicalHistories < ActiveRecord::Migration[6.1]
  FACILITY_ID = "f472c5db-188f-4563-9bc7-9f86a6ed6403"

  def up
    unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
      return print "DedupeIcddrbMedicalHistories is only for production Bangladesh"
    end

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
        .where(patient: {assigned_facility_id: FACILITY_ID})
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
