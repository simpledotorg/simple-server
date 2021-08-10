require "rails_helper"

RSpec.describe Experimentation::DataExport, type: :model do

  TIME_FORMAT = "%Y-%m-%d"

  def create_notification(experiment, template, patient, appt)
    create(:notification,
      experiment: experiment,
      message: template.message,
      patient: patient,
      purpose: :experimental_appointment_reminder,
      remind_on: appt.scheduled_date + template.remind_on_in_days.days,
      reminder_template: template,
      status: "sent",
      subject: appt
    )
  end

  describe "#as_csv" do
    it "exports accurate data in the expected format" do
      experiment = create(:experiment, name: "exportable", experiment_type: "current_patients", start_date: 35.days.ago, end_date: 5.days.ago)
      control_group = create(:treatment_group, experiment: experiment, description: "control")
      single_message_group = create(:treatment_group, experiment: experiment,description: "single message")
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
      n = create_notification(experiment, single_template, single_message_patient, smp_appt1)
      c = create(:communication, notification: n)
      create(:twilio_sms_delivery_detail, communication: c, delivered_on: n.remind_on)
      smp_past_visit_1 = create(:blood_pressure, patient: single_message_patient, device_created_at: 6.months.ago)
      _smp_past_visit_1_pd = create(:prescription_drug, patient: single_message_patient, device_created_at: 6.months.ago)

      cascade_patient = create(:patient)
      appt2 = create(:appointment, patient: cascade_patient, scheduled_date: 22.days.ago)
      n = create_notification(experiment, cascade_template1, cascade_patient, appt2)
      c = create(:communication, notification: n)
      create(:twilio_sms_delivery_detail, communication: c, delivered_on: n.remind_on)
      n = create_notification(experiment, cascade_template2, cascade_patient, appt2)
      c = create(:communication, notification: n)
      create(:twilio_sms_delivery_detail, communication: c, delivered_on: n.remind_on)
      n = create_notification(experiment, cascade_template3, cascade_patient, appt2)
      c = create(:communication, notification: n)
      create(:twilio_sms_delivery_detail, communication: c, delivered_on: n.remind_on)

      Timecop.freeze(experiment.start_date - 1.day) do
        control_group.patients << control_patient
        single_message_group.patients << single_message_patient
        cascade_group.patients << cascade_patient
      end

      subject = described_class.new(experiment.name)
      results = subject.as_csv
      parsed = CSV.parse(results)
      pp parsed

      headers = parsed.first
      appt1_ceation_index = headers.find_index("Appointment 1 Date")
      appt1_days_to_visit_index = headers.find_index("Days To Visit 1")
      appt2_ceation_index = headers.find_index("Appointment 2 Date")
      appt2_days_to_visit_index = headers.find_index("Days To Visit 2")
      first_encounter_index = headers.find_index("Encounter 1 Date")
      second_encounter_index = headers.find_index("Encounter 2 Date")


      expect(parsed.length).to eq 4
      expect(parsed.map {|row| row.length }.uniq.length).to eq 1

      control_patient_row = parsed.find {|row| row.last == control_patient.treatment_group_memberships.first.id.to_s }
      expect(control_patient_row[first_encounter_index]).to eq(control_past_visit_1.device_created_at.strftime(TIME_FORMAT))
      expect(control_patient_row[second_encounter_index]).to eq(control_past_visit_2.device_created_at.strftime(TIME_FORMAT))
      expect(control_patient_row[appt1_ceation_index]).to eq(control_appt1.scheduled_date.strftime(TIME_FORMAT))
      expect(control_patient_row[appt2_ceation_index]).to eq(control_appt2.scheduled_date.strftime(TIME_FORMAT))
      expect(control_patient_row[appt1_days_to_visit_index]).to eq((control_appt1.scheduled_date - control_followup_1.device_created_at.to_date).to_i.to_s)
      expect(control_patient_row[appt2_days_to_visit_index]).to eq((control_appt2.scheduled_date - control_followup_2.device_created_at.to_date).to_i.to_s)

      single_message_patient_row = parsed.find {|row| row.last == single_message_patient.treatment_group_memberships.first.id.to_s }
      expect(single_message_patient_row[first_encounter_index]).to eq(smp_past_visit_1.device_created_at.strftime(TIME_FORMAT))
      expect(single_message_patient_row[second_encounter_index]).to eq(nil)
      expect(single_message_patient_row[appt1_ceation_index]).to eq(smp_appt1.scheduled_date.strftime(TIME_FORMAT))
      expect(single_message_patient_row[appt2_ceation_index]).to eq(nil)
      expect(single_message_patient_row[appt1_days_to_visit_index]).to eq((smp_appt1.scheduled_date - smp_followup_pd.device_created_at.to_date).to_i.to_s)
      expect(single_message_patient_row[appt2_days_to_visit_index]).to be_nil

      cascade_patient_row = parsed.find {|row| row.last == cascade_patient.treatment_group_memberships.first.id.to_s }
      expect(cascade_patient_row[first_encounter_index]).to eq(nil)
      expect(cascade_patient_row[second_encounter_index]).to eq(nil)
    end
  end
end