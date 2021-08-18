require "rails_helper"
require_relative "./experiment_data_examples.rb"

TIME_FORMAT = "%Y-%m-%d"

RSpec.describe Experimentation::Results, type: :model do
  describe "#as_csv" do
    include_context "active experiment data"

    it "exports accurate data in the expected format" do
      subject = described_class.new(@experiment.name)
      subject.aggregate_data
      results = subject.patient_data_aggregate

      pp results

      {"Experiment Name"=>@experiment.name,
        "Treatment Group"=>@control_group.description,
        "Experiment Inclusion Date"=>Tue, 13 Jul 2021,
        "Appointments"=>
         [{"Appointment 1 Creation Date"=>Fri, 09 Jul 2021,
           "Appointment 1 Date"=>Mon, 19 Jul 2021},
          {"Appointment 2 Creation Date"=>Fri, 09 Jul 2021,
           "Appointment 2 Date"=>Thu, 29 Jul 2021}],
        "Blood Pressures"=>
         [{"Blood Pressure 1 Date"=>Fri, 18 Dec 2020},
          {"Blood Pressure 2 Date"=>Tue, 18 May 2021},
          {"Blood Pressure 3 Date"=>Wed, 21 Jul 2021}],
        "Communications"=>[],
        "Patient Gender"=>"female",
        "Patient Age"=>88,
        "Patient Risk Level"=>1,
        "Assigned Facility Name"=>"Facility 1",
        "Assigned Facility Type"=>"PHC",
        "Assigned Facility State"=>"Punjab",
        "Assigned Facility District"=>"South Hazelshire",
        "Assigned Facility Block"=>"Paradise Pointe",
        "Patient Registration Date"=>Wed, 18 Aug 2021,
        "Patient Id"=>1343},
       {"Experiment Name"=>"exportable",
        "Treatment Group"=>"single message",
        "Experiment Inclusion Date"=>Tue, 13 Jul 2021,
        "Appointments"=>
         [{"Appointment 1 Creation Date"=>Wed, 18 Aug 2021,
           "Appointment 1 Date"=>Thu, 29 Jul 2021}],
        "Blood Pressures"=>[{"Blood Pressure 1 Date"=>Thu, 18 Feb 2021}],
        "Communications"=>
         [{"Message 1 Type"=>"whatsapp",
           "Message 1 Date Sent"=>Wed, 28 Jul 2021,
           "Message 1 Status"=>"read",
           "Message 1 Text Identifier"=>"single group message"}],
        "Patient Gender"=>"male",
        "Patient Age"=>46,
        "Patient Risk Level"=>1,
        "Assigned Facility Name"=>"Facility 17",
        "Assigned Facility Type"=>"PHC",
        "Assigned Facility State"=>"Maharashtra",
        "Assigned Facility District"=>"Acacia County",
        "Assigned Facility Block"=>"Royal Village",
        "Patient Registration Date"=>Wed, 18 Aug 2021,
        "Patient Id"=>1344}


      control_patient_row = []

      # test control patient data
      control_patient_row = parsed.find { |row| row.last == @control_patient.treatment_group_memberships.first.id.to_s }

      expect(control_patient_row[first_encounter_index]).to eq(@control_past_visit_1.device_created_at.strftime(TIME_FORMAT))
      expect(control_patient_row[second_encounter_index]).to eq(@control_past_visit_2.device_created_at.strftime(TIME_FORMAT))

      expect(control_patient_row[appt1_created_index]).to eq(@control_appt1.device_created_at.strftime(TIME_FORMAT))
      expect(control_patient_row[appt1_scheduled_index]).to eq(@control_appt1.scheduled_date.strftime(TIME_FORMAT))
      expect(control_patient_row[appt2_created_index]).to eq(@control_appt2.device_created_at.strftime(TIME_FORMAT))
      expect(control_patient_row[appt2_scheduled_index]).to eq(@control_appt2.scheduled_date.strftime(TIME_FORMAT))

      [first_message_range, second_message_range, third_message_range, fourth_message_range].each do |range|
        expect(control_patient_row[range].uniq).to eq([nil])
      end

      # test single message patient data
      single_message_patient_row = parsed.find { |row| row.last == @single_message_patient.treatment_group_memberships.first.id.to_s }

      expect(single_message_patient_row[first_encounter_index]).to eq(@smp_past_visit_1.device_created_at.strftime(TIME_FORMAT))
      expect(single_message_patient_row[second_encounter_index]).to eq(nil)

      expect(single_message_patient_row[appt1_created_index]).to eq(@smp_appt1.device_created_at.strftime(TIME_FORMAT))
      expect(single_message_patient_row[appt1_scheduled_index]).to eq(@smp_appt1.scheduled_date.strftime(TIME_FORMAT))

      expect(single_message_patient_row[appt2_created_index]).to eq(nil)
      expect(single_message_patient_row[appt2_scheduled_index]).to eq(nil)

      expected_first_communication_data = [
        @smp_communication.communication_type,
        @smp_communication.detailable.delivered_on.strftime(TIME_FORMAT),
        @smp_communication.detailable.result,
        @smp_notification.message
      ]
      expect(single_message_patient_row[first_message_range]).to eq(expected_first_communication_data)
      [second_message_range, third_message_range, fourth_message_range].each do |range|
        expect(single_message_patient_row[range].uniq).to eq([nil])
      end

      # test cascade patient data
      cascade_patient_row = parsed.find { |row| row.last == @cascade_patient.treatment_group_memberships.first.id.to_s }

      expect(cascade_patient_row[first_encounter_index]).to eq(nil)
      expect(cascade_patient_row[second_encounter_index]).to eq(nil)

      expect(cascade_patient_row[appt1_created_index]).to eq(@cascade_patient_appt.device_created_at.strftime(TIME_FORMAT))
      expect(cascade_patient_row[appt1_scheduled_index]).to eq(@cascade_patient_appt.scheduled_date.strftime(TIME_FORMAT))
      expect(cascade_patient_row[appt2_created_index]).to eq(nil)
      expect(cascade_patient_row[appt2_scheduled_index]).to eq(nil)

      expected_first_communication_data = [
        @cascade_comm1.communication_type,
        @cascade_comm1.detailable.delivered_on.strftime(TIME_FORMAT),
        @cascade_comm1.detailable.result,
        @cascade_notification1.message
      ]
      expect(cascade_patient_row[first_message_range]).to eq(expected_first_communication_data)
      expected_second_communication_data = [
        @cascade_comm2.communication_type,
        @cascade_comm2.detailable.delivered_on.strftime(TIME_FORMAT),
        @cascade_comm2.detailable.result,
        @cascade_notification1.message
      ]
      expect(cascade_patient_row[second_message_range]).to eq(expected_second_communication_data)
      expected_third_communication_data = [
        @cascade_comm3.communication_type,
        @cascade_comm3.detailable.delivered_on.strftime(TIME_FORMAT),
        @cascade_comm3.detailable.result,
        @cascade_notification2.message
      ]
      expect(cascade_patient_row[third_message_range]).to eq(expected_third_communication_data)
      expected_fourth_communication_data = [
        @cascade_comm4.communication_type,
        @cascade_comm4.detailable.delivered_on.strftime(TIME_FORMAT),
        @cascade_comm4.detailable.result,
        @cascade_notification2.message
      ]
      expect(cascade_patient_row[fourth_message_range]).to eq(expected_fourth_communication_data)

      # csv_data = subject.mail_csv
      # csv_data.attachments.to_json
    end
  end
end
