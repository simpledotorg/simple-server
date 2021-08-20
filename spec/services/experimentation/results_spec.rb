require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe Experimentation::Results, type: :model do
  describe "patient_data_aggregate" do
    include_context "active experiment data"

    it "aggregates data for all experiment patients" do
      subject = described_class.new(@experiment.name)
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
        "Assigned Facility Type" => @control_patient.assigned_facility.facility_type,
        "Assigned Facility State" => @control_patient.assigned_facility.state,
        "Assigned Facility District" => @control_patient.assigned_facility.district,
        "Assigned Facility Block" => @control_patient.assigned_facility.block,
        "Patient Registration Date" => @control_patient.registration_date.to_date,
        "Patient Id" => @control_patient.treatment_group_memberships.first.id
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
                              "Message 1 Text Identifier" => @smp_notification.message}],
        "Patient Gender" => @single_message_patient.gender,
        "Patient Age" => @single_message_patient.age,
        "Patient Risk Level" => @single_message_patient.risk_priority,
        "Assigned Facility Name" => @single_message_patient.assigned_facility.name,
        "Assigned Facility Type" => @single_message_patient.assigned_facility.facility_type,
        "Assigned Facility State" => @single_message_patient.assigned_facility.state,
        "Assigned Facility District" => @single_message_patient.assigned_facility.district,
        "Assigned Facility Block" => @single_message_patient.assigned_facility.block,
        "Patient Registration Date" => @single_message_patient.registration_date.to_date,
        "Patient Id" => @single_message_patient.treatment_group_memberships.first.id
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
        "Assigned Facility Type" => @cascade_patient.assigned_facility.facility_type,
        "Assigned Facility State" => @cascade_patient.assigned_facility.state,
        "Assigned Facility District" => @cascade_patient.assigned_facility.district,
        "Assigned Facility Block" => @cascade_patient.assigned_facility.block,
        "Patient Registration Date" => @cascade_patient.registration_date.to_date,
        "Patient Id" => @cascade_patient.treatment_group_memberships.first.id
      }

      expected_results = [
        expected_control_patient_result,
        expected_single_message_patient_result,
        expected_cascade_patient_result
      ]
      expect(results).to eq(expected_results)
    end
  end

  describe "#as_csv" do
    include_context "active experiment data"

    it "returns a csv with the expected data" do
      expected_file_contents = %(Experiment Name,Treatment Group,Experiment Inclusion Date,\
Appointment 1 Creation Date,Appointment 1 Date,Appointment 2 Creation Date,Appointment 2 Date,Blood Pressure 1 Date,\
Blood Pressure 2 Date,Blood Pressure 3 Date,Message 1 Type,Message 1 Date Sent,Message 1 Status,\
Message 1 Text Identifier,Message 2 Type,Message 2 Date Sent,Message 2 Status,Message 2 Text Identifier,\
Message 3 Type,Message 3 Date Sent,Message 3 Status,Message 3 Text Identifier,Message 4 Type,Message 4 Date Sent,\
Message 4 Status,Message 4 Text Identifier,Patient Gender,Patient Age,Patient Risk Level,Assigned Facility Name,\
Assigned Facility Type,Assigned Facility State,Assigned Facility District,Assigned Facility Block,\
Patient Registration Date,Patient Id\nexportable,control,2020-12-31,2020-12-25,2021-01-08,2020-12-25,2021-01-15,\
2020-05-01,2020-10-01,2021-01-10,,,,,,,,,,,,,,,,,female,60,1,Bangalore Clinic,City,Karnataka,South,Red Zone,\
2020-01-01,#{@control_patient.treatment_group_memberships.last.id}\nexportable,single message,2020-12-31,\
2020-12-25,2021-01-15,,,2020-07-01,,,whatsapp,2021-01-14,read,single group message,,,,,,,,,,,,,male,70,1,Goa Clinic,\
Village,Goa,South,Blue Zone,2020-01-01,#{@single_message_patient.treatment_group_memberships.last.id}\n\
exportable,cascade,2020-12-31,2020-12-25,2021-01-22,,,2020-11-01,,,whatsapp,2021-01-21,failed,cascade 1,sms,\
2021-01-21,delivered,cascade 1,whatsapp,2021-01-22,failed,cascade 2,sms,2021-01-22,delivered,cascade 2,female,50,1,\
Bangalore Clinic,City,Karnataka,South,Red Zone,2020-01-01,#{@cascade_patient.treatment_group_memberships.last.id}\n)

      service = described_class.new(@experiment.name)
      expect(service.as_csv).to eq(expected_file_contents)
    end
  end
end
