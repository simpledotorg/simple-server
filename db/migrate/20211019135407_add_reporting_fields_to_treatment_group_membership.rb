class AddReportingFieldsToTreatmentGroupMembership < ActiveRecord::Migration[5.2]
  def change
    add_reference :treatment_group_memberships, :experiment, foreign_key: true, type: :uuid
    add_reference :treatment_group_memberships, :appointment, foreign_key: true, type: :uuid

    add_column :treatment_group_memberships, "experiment_name", :string
    add_column :treatment_group_memberships, "treatment_group_name", :string
    add_column :treatment_group_memberships, "experiment_inclusion_date", :datetime
    add_column :treatment_group_memberships, "expected_return_date", :datetime
    add_column :treatment_group_memberships, "expected_return_facility_id", :uuid
    add_column :treatment_group_memberships, "expected_return_facility_type", :string
    add_column :treatment_group_memberships, "expected_return_facility_name", :string
    add_column :treatment_group_memberships, "expected_return_facility_block", :string
    add_column :treatment_group_memberships, "expected_return_facility_district", :string
    add_column :treatment_group_memberships, "expected_return_facility_state", :string
    add_column :treatment_group_memberships, "appointment_creation_time", :datetime
    add_column :treatment_group_memberships, "appointment_creation_facility_id", :uuid
    add_column :treatment_group_memberships, "appointment_creation_facility_type", :string
    add_column :treatment_group_memberships, "appointment_creation_facility_name", :string
    add_column :treatment_group_memberships, "appointment_creation_facility_block", :string
    add_column :treatment_group_memberships, "appointment_creation_facility_district", :string
    add_column :treatment_group_memberships, "appointment_creation_facility_state", :string
    add_column :treatment_group_memberships, "gender", :string
    add_column :treatment_group_memberships, "age", :integer
    add_column :treatment_group_memberships, "risk_level", :string
    add_column :treatment_group_memberships, "diagnosed_htn", :string
    add_column :treatment_group_memberships, "assigned_facility_id", :uuid
    add_column :treatment_group_memberships, "assigned_facility_name", :string
    add_column :treatment_group_memberships, "assigned_facility_type", :string
    add_column :treatment_group_memberships, "assigned_facility_block", :string
    add_column :treatment_group_memberships, "assigned_facility_district", :string
    add_column :treatment_group_memberships, "assigned_facility_state", :string
    add_column :treatment_group_memberships, "registration_facility_id", :uuid
    add_column :treatment_group_memberships, "registration_facility_name", :string
    add_column :treatment_group_memberships, "registration_facility_type", :string
    add_column :treatment_group_memberships, "registration_facility_block", :string
    add_column :treatment_group_memberships, "registration_facility_district", :string
    add_column :treatment_group_memberships, "registration_facility_state", :string
    add_column :treatment_group_memberships, "visit_date", :date
    add_column :treatment_group_memberships, "visit_facility_id", :uuid
    add_column :treatment_group_memberships, "visit_facility_name", :string
    add_column :treatment_group_memberships, "visit_facility_type", :string
    add_column :treatment_group_memberships, "visit_facility_block", :string
    add_column :treatment_group_memberships, "visit_facility_district", :string
    add_column :treatment_group_memberships, "visit_facility_state", :string
    add_column :treatment_group_memberships, "visit_blood_pressure_id", :uuid
    add_column :treatment_group_memberships, "visit_blood_sugar_id", :uuid
    add_column :treatment_group_memberships, "visit_prescription_drug_created", :boolean
    add_column :treatment_group_memberships, "days_to_visit", :integer
    add_column :treatment_group_memberships, "messages", :jsonb
    add_column :treatment_group_memberships, "deleted_at", :datetime
  end
end
