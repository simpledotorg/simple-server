require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe Experimentation::Results, type: :model do
  describe "#aggregate_data" do
    include_context "active experiment data"

    it "aggregates data for all experiment patients" do
      subject = described_class.new(@experiment.name)
      subject.aggregate_data
      results = subject.patient_data_aggregate

      expected_control_patient_result = {
        "Experiment Name" => @experiment.name,
        "Treatment Group" => @control_group.description,
        "Experiment Inclusion Date" => @control_patient.treatment_group_memberships.first.created_at.to_date,
        "Appointments" =>
         [{"Appointment 1 Creation Date" => @control_appt_1.device_created_at.to_date,
           "Appointment 1 Date" => @control_appt_1.scheduled_date.to_date},
          {"Appointment 2 Creation Date" => @control_appt_2.device_created_at.to_date,
           "Appointment 2 Date" => @control_appt_2.scheduled_date.to_date}],
        "Blood Pressures" =>
         [{"Blood Pressure 1 Date" => @control_past_visit_1.device_created_at.to_date},
          {"Blood Pressure 2 Date" => @control_past_visit_2.device_created_at.to_date},
          {"Blood Pressure 3 Date" => @control_followup_1.device_created_at.to_date}],
        "Communications" => [],
        "Patient Gender" => @control_patient.gender,
        "Patient Age" => @control_patient.age,
        "Patient Risk Level" => @control_patient.risk_priority,
        "Assigned Facility Name" => @control_patient.assigned_facility.name,
        "Assigned Facility Type" =>  @control_patient.assigned_facility.facility_type,
        "Assigned Facility State" =>  @control_patient.assigned_facility.state,
        "Assigned Facility District" => @control_patient.assigned_facility.district,
        "Assigned Facility Block" => @control_patient.assigned_facility.block,
        "Patient Registration Date" => @control_patient.registration_date.to_date,
        "Patient Id" =>  @control_patient.treatment_group_memberships.first.id
      }

      expected_single_message_patient_result = {
        "Experiment Name" => @experiment.name,
        "Treatment Group" => @single_message_group.description,
        "Experiment Inclusion Date" => @single_message_patient.treatment_group_memberships.first.created_at.to_date,
        "Appointments" =>
         [{"Appointment 1 Creation Date" => @smp_appt.device_created_at.to_date,
           "Appointment 1 Date" => @smp_appt.scheduled_date.to_date}],
        "Blood Pressures" =>
         [{"Blood Pressure 1 Date" => @smp_past_visit_1.device_created_at.to_date}],
        "Communications" => [{"Message 1 Type" => @smp_communication.communication_type,
          "Message 1 Date Sent" => @smp_communication.detailable.delivered_on.to_date,
          "Message 1 Status" => @smp_communication.detailable.result,
          "Message 1 Text Identifier" => @smp_notification.message
          }],
        "Patient Gender" => @single_message_patient.gender,
        "Patient Age" => @single_message_patient.age,
        "Patient Risk Level" => @single_message_patient.risk_priority,
        "Assigned Facility Name" => @single_message_patient.assigned_facility.name,
        "Assigned Facility Type" =>  @single_message_patient.assigned_facility.facility_type,
        "Assigned Facility State" =>  @single_message_patient.assigned_facility.state,
        "Assigned Facility District" => @single_message_patient.assigned_facility.district,
        "Assigned Facility Block" => @single_message_patient.assigned_facility.block,
        "Patient Registration Date" => @single_message_patient.registration_date.to_date,
        "Patient Id" =>  @single_message_patient.treatment_group_memberships.first.id
      }

      expected_cascade_patient_result = {
        "Experiment Name" => @experiment.name,
        "Treatment Group" => @cascade_group.description,
        "Experiment Inclusion Date" => @cascade_patient.treatment_group_memberships.first.created_at.to_date,
        "Appointments" =>
         [{"Appointment 1 Creation Date" => @cascade_patient_appt.device_created_at.to_date,
           "Appointment 1 Date" => @cascade_patient_appt.scheduled_date.to_date}],
        "Blood Pressures" =>
         [{"Blood Pressure 1 Date" => @cascade_past_visit_1.device_created_at.to_date}],
        "Communications" => [
          {"Message 1 Type" => @cascade_communication_1.communication_type,
          "Message 1 Date Sent" => @cascade_communication_1.detailable.delivered_on.to_date,
          "Message 1 Status" => @cascade_communication_1.detailable.result,
          "Message 1 Text Identifier" => @cascade_notification_1.message},
          {"Message 2 Type" => @cascade_communication_2.communication_type,
          "Message 2 Date Sent" => @cascade_communication_2.detailable.delivered_on.to_date,
          "Message 2 Status" => @cascade_communication_2.detailable.result,
          "Message 2 Text Identifier" => @cascade_notification_1.message},
          {"Message 3 Type" => @cascade_communication_3.communication_type,
          "Message 3 Date Sent" => @cascade_communication_3.detailable.delivered_on.to_date,
          "Message 3 Status" => @cascade_communication_3.detailable.result,
          "Message 3 Text Identifier" => @cascade_notification_2.message},
          {"Message 4 Type" => @cascade_communication_4.communication_type,
          "Message 4 Date Sent" => @cascade_communication_4.detailable.delivered_on.to_date,
          "Message 4 Status" => @cascade_communication_4.detailable.result,
          "Message 4 Text Identifier" => @cascade_notification_2.message}
        ],
        "Patient Gender" => @cascade_patient.gender,
        "Patient Age" => @cascade_patient.age,
        "Patient Risk Level" => @cascade_patient.risk_priority,
        "Assigned Facility Name" => @cascade_patient.assigned_facility.name,
        "Assigned Facility Type" =>  @cascade_patient.assigned_facility.facility_type,
        "Assigned Facility State" =>  @cascade_patient.assigned_facility.state,
        "Assigned Facility District" => @cascade_patient.assigned_facility.district,
        "Assigned Facility Block" => @cascade_patient.assigned_facility.block,
        "Patient Registration Date" => @cascade_patient.registration_date.to_date,
        "Patient Id" =>  @cascade_patient.treatment_group_memberships.first.id
      }

      expected_results = [
        expected_control_patient_result,
        expected_single_message_patient_result,
        expected_cascade_patient_result
      ]
      expect(results).to eq(expected_results)
    end
  end
end
