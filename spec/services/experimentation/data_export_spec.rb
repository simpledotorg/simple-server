require "rails_helper"

TIME_FORMAT = "%Y-%m-%d"

RSpec.describe Experimentation::DataExport, type: :model do
  def create_notification(experiment, template, patient, appt, status)
    create(:notification,
      experiment: experiment,
      message: template.message,
      patient: patient,
      purpose: :experimental_appointment_reminder,
      remind_on: appt.scheduled_date + template.remind_on_in_days.days,
      reminder_template: template,
      status: status,
      subject: appt)
  end

  describe "#as_csv" do
    it "exports accurate data in the expected format" do
      experiment = create(:experiment, name: "exportable", experiment_type: "current_patients", start_date: 35.days.ago, end_date: 5.days.ago)
      control_group = create(:treatment_group, experiment: experiment, description: "control")
      single_message_group = create(:treatment_group, experiment: experiment, description: "single message")
      single_template = create(:reminder_template, treatment_group: single_message_group, remind_on_in_days: -1, message: "single group message")
      cascade_group = create(:treatment_group, experiment: experiment, description: "cascade group")
      cascade_template1 = create(:reminder_template, treatment_group: single_message_group, remind_on_in_days: -1, message: "cascade 1")
      cascade_template2 = create(:reminder_template, treatment_group: single_message_group, remind_on_in_days: 0, message: "cascade 2")
      cascade_template3 = create(:reminder_template, treatment_group: single_message_group, remind_on_in_days: 3, message: "cascade 3")

      control_patient = create(:patient)
      control_appt1 = create(:appointment, patient: control_patient, scheduled_date: 30.days.ago, device_created_at: 40.days.ago)
      control_followup_1 = create(:blood_pressure, patient: control_patient, device_created_at: 28.days.ago)
      control_appt2 = create(:appointment, patient: control_patient, scheduled_date: 20.days.ago, device_created_at: 40.days.ago)
      control_followup_2 = create(:blood_sugar, patient: control_patient, device_created_at: 21.days.ago)
      control_past_visit_1 = create(:blood_pressure, patient: control_patient, device_created_at: 8.months.ago)
      control_past_visit_2 = create(:blood_sugar, patient: control_patient, device_created_at: 2.months.ago)
      _control_past_visit_2_bs = create(:blood_sugar, patient: control_patient, device_created_at: 2.months.ago)

      single_message_patient = create(:patient)
      smp_appt1 = create(:appointment, patient: single_message_patient, scheduled_date: 20.days.ago)
      smp_followup_pd = create(:prescription_drug, patient: single_message_patient, device_created_at: 21.days.ago)
      smp_notification = create_notification(experiment, single_template, single_message_patient, smp_appt1, "sent")
      smp_communication = create(:communication, notification: smp_notification, communication_type: "whatsapp")
      create(:twilio_sms_delivery_detail, communication: smp_communication, delivered_on: smp_notification.remind_on, result: "read")
      smp_past_visit_1 = create(:blood_pressure, patient: single_message_patient, device_created_at: 6.months.ago)
      _smp_past_visit_1_pd = create(:prescription_drug, patient: single_message_patient, device_created_at: 6.months.ago)

      cascade_patient = create(:patient)
      cascade_patient_appt = create(:appointment, patient: cascade_patient, scheduled_date: 22.days.ago)
      cascade_notification1 = create_notification(experiment, cascade_template1, cascade_patient, cascade_patient_appt, "sent")
      cascade_comm1 = create(:communication, notification: cascade_notification1, communication_type: "whatsapp")
      create(:twilio_sms_delivery_detail, communication: cascade_comm1, delivered_on: cascade_notification1.remind_on, result: "failed")
      cascade_comm2 = create(:communication, notification: cascade_notification1, communication_type: "sms")
      create(:twilio_sms_delivery_detail, communication: cascade_comm2, delivered_on: cascade_notification1.remind_on, result: "delivered")
      cascade_notification2 = create_notification(experiment, cascade_template2, cascade_patient, cascade_patient_appt, "sent")
      cascade_comm3 = create(:communication, notification: cascade_notification2, communication_type: "whatsapp")
      create(:twilio_sms_delivery_detail, communication: cascade_comm3, delivered_on: cascade_notification2.remind_on, result: "failed")
      cascade_comm4 = create(:communication, notification: cascade_notification2, communication_type: "sms")
      create(:twilio_sms_delivery_detail, communication: cascade_comm4, delivered_on: cascade_notification2.remind_on, result: "delivered")
      _cascade_notification3 = create_notification(experiment, cascade_template3, cascade_patient, cascade_patient_appt, "cancelled")

      Timecop.freeze(experiment.start_date - 1.day) do
        control_group.patients << control_patient
        single_message_group.patients << single_message_patient
        cascade_group.patients << cascade_patient
      end

      subject = described_class.new(experiment.name)
      results = subject.as_csv
      parsed = CSV.parse(results)
      pp parsed

      # grab indexes from header row
      headers = parsed.first
      appt1_start_index = headers.find_index("Appointment 1 Creation Date")
      appt1_end_index = appt1_start_index + 9
      appt2_start_index = headers.find_index("Appointment 2 Creation Date")
      appt2_end_index = appt2_start_index + 9
      first_encounter_index = headers.find_index("Blood Pressure 1 Date")
      second_encounter_index = headers.find_index("Blood Pressure 2 Date")
      first_message_index = headers.find_index("Message 1 Type")
      first_message_range = (first_message_index..(first_message_index + 3))
      second_message_index = headers.find_index("Message 2 Type")
      second_message_range = (second_message_index..(second_message_index + 3))
      third_message_index = headers.find_index("Message 3 Type")
      third_message_range = (third_message_index..(third_message_index + 3))
      fourth_message_index = headers.find_index("Message 4 Type")
      fourth_message_range = (fourth_message_index..(fourth_message_index + 3))

      expect(parsed.length).to eq 4
      expect(parsed.map { |row| row.length }.uniq.length).to eq 1

      # test control patient data
      control_patient_row = parsed.find { |row| row.last == control_patient.treatment_group_memberships.first.id.to_s }

      expect(control_patient_row[first_encounter_index]).to eq(control_past_visit_1.device_created_at.strftime(TIME_FORMAT))
      expect(control_patient_row[second_encounter_index]).to eq(control_past_visit_2.device_created_at.strftime(TIME_FORMAT))

      control_patient_appt1_data = control_patient_row[appt1_start_index..appt1_end_index]
      expected_appt1_data = [
        control_appt1.device_created_at.strftime(TIME_FORMAT),
        control_appt1.scheduled_date.strftime(TIME_FORMAT),
        control_followup_1.device_created_at.strftime(TIME_FORMAT),
        (control_appt1.scheduled_date - control_followup_1.device_created_at.to_date).to_i.to_s,
        "true",
        control_followup_1.facility.name,
        control_followup_1.facility.facility_type,
        control_followup_1.facility.state,
        control_followup_1.facility.district,
        control_followup_1.facility.block
      ]
      expect(control_patient_appt1_data).to match_array(expected_appt1_data)

      control_patient_appt2_data = control_patient_row[appt2_start_index..appt2_end_index]
      expected_appt2_data = [
        control_appt2.device_created_at.strftime(TIME_FORMAT),
        control_appt2.scheduled_date.strftime(TIME_FORMAT),
        control_followup_2.device_created_at.strftime(TIME_FORMAT),
        (control_appt2.scheduled_date - control_followup_2.device_created_at.to_date).to_i.to_s,
        "false",
        control_followup_2.facility.name,
        control_followup_2.facility.facility_type,
        control_followup_2.facility.state,
        control_followup_2.facility.district,
        control_followup_2.facility.block
      ]
      expect(control_patient_appt2_data).to match_array(expected_appt2_data)

      [first_message_range, second_message_range, third_message_range, fourth_message_range].each do |range|
        expect(control_patient_row[range].uniq).to eq([nil])
      end

      # test single message patient data
      single_message_patient_row = parsed.find { |row| row.last == single_message_patient.treatment_group_memberships.first.id.to_s }

      expect(single_message_patient_row[first_encounter_index]).to eq(smp_past_visit_1.device_created_at.strftime(TIME_FORMAT))
      expect(single_message_patient_row[second_encounter_index]).to eq(nil)

      single_message_patient_appt1_data = single_message_patient_row[appt1_start_index..appt1_end_index]
      expected_appt1_data = [
        smp_appt1.device_created_at.strftime(TIME_FORMAT),
        smp_appt1.scheduled_date.strftime(TIME_FORMAT),
        smp_followup_pd.device_created_at.strftime(TIME_FORMAT),
        (smp_appt1.scheduled_date - smp_followup_pd.device_created_at.to_date).to_i.to_s,
        "false",
        smp_followup_pd.facility.name,
        smp_followup_pd.facility.facility_type,
        smp_followup_pd.facility.state,
        smp_followup_pd.facility.district,
        smp_followup_pd.facility.block
      ]
      expect(single_message_patient_appt1_data).to match_array(expected_appt1_data)

      expect(single_message_patient_row[appt2_start_index..appt2_end_index]).to eq(Array.new(10, nil))

      expected_first_communication_data = [
        smp_communication.communication_type,
        smp_communication.detailable.delivered_on.strftime(TIME_FORMAT),
        smp_communication.detailable.result,
        smp_notification.message
      ]
      expect(single_message_patient_row[first_message_range]).to eq(expected_first_communication_data)
      [second_message_range, third_message_range, fourth_message_range].each do |range|
        expect(single_message_patient_row[range].uniq).to eq([nil])
      end

      # test cascade patient data
      cascade_patient_row = parsed.find { |row| row.last == cascade_patient.treatment_group_memberships.first.id.to_s }

      expect(cascade_patient_row[first_encounter_index]).to eq(nil)
      expect(cascade_patient_row[second_encounter_index]).to eq(nil)
      cascade_patient_appt1_data = cascade_patient_row[appt1_start_index..appt1_end_index]
      expected_appt1_data = [
        cascade_patient_appt.device_created_at.strftime(TIME_FORMAT),
        cascade_patient_appt.scheduled_date.strftime(TIME_FORMAT),
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil
      ]
      expect(cascade_patient_appt1_data).to match_array(expected_appt1_data)

      expect(cascade_patient_row[appt2_start_index..appt2_end_index]).to eq(Array.new(10, nil))

      expected_first_communication_data = [
        cascade_comm1.communication_type,
        cascade_comm1.detailable.delivered_on.strftime(TIME_FORMAT),
        cascade_comm1.detailable.result,
        cascade_notification1.message
      ]
      expect(cascade_patient_row[first_message_range]).to eq(expected_first_communication_data)
      expected_second_communication_data = [
        cascade_comm2.communication_type,
        cascade_comm2.detailable.delivered_on.strftime(TIME_FORMAT),
        cascade_comm2.detailable.result,
        cascade_notification1.message
      ]
      expect(cascade_patient_row[second_message_range]).to eq(expected_second_communication_data)
      expected_third_communication_data = [
        cascade_comm3.communication_type,
        cascade_comm3.detailable.delivered_on.strftime(TIME_FORMAT),
        cascade_comm3.detailable.result,
        cascade_notification2.message
      ]
      expect(cascade_patient_row[third_message_range]).to eq(expected_third_communication_data)
      expected_fourth_communication_data = [
        cascade_comm4.communication_type,
        cascade_comm4.detailable.delivered_on.strftime(TIME_FORMAT),
        cascade_comm4.detailable.result,
        cascade_notification2.message
      ]
      expect(cascade_patient_row[fourth_message_range]).to eq(expected_fourth_communication_data)
    end
  end
end
