class MergeDuplicatePatientsJob < ApplicationJob
  def perform
    identifier_type = PatientBusinessIdentifier.identifier_types[:simple_bp_passport]

    PatientBusinessIdentifier
      .select("identifier, array_agg(distinct patient_id) as patient_ids")
      .joins(:patient)
      .where.not(identifier: "")
      .where(identifier_type: identifier_type)
      .group(:identifier, :full_name)
      .having("COUNT(distinct patient_id) > 1")
      .to_sql
  end
end
