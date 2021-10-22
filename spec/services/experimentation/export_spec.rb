require "rails_helper"

RSpec.describe Experimentation::Export, type: :model do
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

  before do
    experiment_start_time = Date.parse("January 1, 2021")
    experiment_end_time = Date.parse("January 31, 2021")
    one_year_ago = experiment_start_time - 1.year
    first_week_of_experiment = experiment_start_time + 1.week
    second_week_of_experiment = experiment_start_time + 2.weeks
    third_week_of_experiment = experiment_start_time + 3.weeks
    week_before_experiment = experiment_start_time - 1.week

    @experiment = create(:experiment, name: "exportable", experiment_type: "current_patients", start_time: experiment_start_time, end_time: experiment_end_time)
    @control_group = create(:treatment_group, experiment: @experiment, description: "control")
    @single_message_group = create(:treatment_group, experiment: @experiment, description: "single message")
    @single_template = create(:reminder_template, treatment_group: @single_message_group, remind_on_in_days: -1, message: "single group message")
    @cascade_group = create(:treatment_group, experiment: @experiment, description: "cascade")
    @cascade_template_1 = create(:reminder_template, treatment_group: @cascade_group, remind_on_in_days: -1, message: "cascade 1")
    @cascade_template_2 = create(:reminder_template, treatment_group: @cascade_group, remind_on_in_days: 0, message: "cascade 2")
    @cascade_template_3 = create(:reminder_template, treatment_group: @cascade_group, remind_on_in_days: 3, message: "cascade 3")

    @facility_1 = create(:facility, name: "Bangalore Clinic", facility_type: "City", state: "Karnataka", district: "South", zone: "Red Zone")
    @facility_2 = create(:facility, name: "Goa Clinic", facility_type: "Village", state: "Goa", district: "South", zone: "Blue Zone")

    @control_patient = create(:patient, assigned_facility: @facility_1, age: 60, gender: "female", device_created_at: one_year_ago)
    @control_appt_1 = create(:appointment, patient: @control_patient, scheduled_date: first_week_of_experiment, device_created_at: week_before_experiment, facility: @facility_1)
    @control_appt_1_followup_days = 2
    @control_followup_1 = create(:blood_pressure, :hypertensive, patient: @control_patient, device_created_at: first_week_of_experiment + @control_appt_1_followup_days.days, facility: @facility_1)
    @control_appt_2 = create(:appointment, patient: @control_patient, scheduled_date: second_week_of_experiment, device_created_at: week_before_experiment, facility: @facility_1)
    @control_past_visit_1 = create(:blood_pressure, :hypertensive, patient: @control_patient, device_created_at: experiment_start_time - 8.months, facility: @facility_1)
    @control_past_visit_2 = create(:blood_pressure, :hypertensive, patient: @control_patient, device_created_at: experiment_start_time - 3.months, facility: @facility_1)

    @single_message_patient = create(:patient, assigned_facility: @facility_2, age: 70, gender: "male", device_created_at: one_year_ago)
    @smp_appt = create(:appointment, patient: @single_message_patient, scheduled_date: second_week_of_experiment, device_created_at: week_before_experiment, facility: @facility_2)
    @smp_notification = create_notification(@experiment, @single_template, @single_message_patient, @smp_appt, "sent")
    @smp_communication = create(:communication, notification: @smp_notification, communication_type: "whatsapp")
    create(:twilio_sms_delivery_detail, communication: @smp_communication, delivered_on: @smp_notification.remind_on, result: "read")
    @smp_past_visit_1 = create(:blood_pressure, :hypertensive, patient: @single_message_patient, device_created_at: experiment_start_time - 6.months, facility: @facility_2)
    @smp_appt_followup_days = 3
    @smp_followup_1 = create(:blood_pressure, :hypertensive, patient: @single_message_patient, device_created_at: @smp_appt.scheduled_date + @smp_appt_followup_days.days, facility: @facility_2)

    @cascade_patient = create(:patient, assigned_facility: @facility_1, age: 50, gender: "female", device_created_at: one_year_ago)
    @cascade_past_visit_1 = create(:blood_pressure, :hypertensive, patient: @cascade_patient, device_created_at: experiment_start_time - 2.months, facility: @facility_1)
    @cascade_patient_appt = create(:appointment, patient: @cascade_patient, scheduled_date: third_week_of_experiment, device_created_at: week_before_experiment, facility: @facility_1)
    @cascade_notification_1 = create_notification(@experiment, @cascade_template_1, @cascade_patient, @cascade_patient_appt, "sent")
    @cascade_communication_1 = create(:communication, notification: @cascade_notification_1, communication_type: "whatsapp")
    create(:twilio_sms_delivery_detail, communication: @cascade_communication_1, delivered_on: @cascade_notification_1.remind_on, result: "failed")
    @cascade_communication_2 = create(:communication, notification: @cascade_notification_1, communication_type: "sms")
    create(:twilio_sms_delivery_detail, communication: @cascade_communication_2, delivered_on: @cascade_notification_1.remind_on, result: "delivered")
    @cascade_notification_2 = create_notification(@experiment, @cascade_template_2, @cascade_patient, @cascade_patient_appt, "sent")
    @cascade_communication_3 = create(:communication, notification: @cascade_notification_2, communication_type: "whatsapp")
    create(:twilio_sms_delivery_detail, communication: @cascade_communication_3, delivered_on: @cascade_notification_2.remind_on, result: "failed")
    @cascade_communication_4 = create(:communication, notification: @cascade_notification_2, communication_type: "sms")
    create(:twilio_sms_delivery_detail, communication: @cascade_communication_4, delivered_on: @cascade_notification_2.remind_on, result: "delivered")
    _cascade_notification_3 = create_notification(@experiment, @cascade_template_3, @cascade_patient, @cascade_patient_appt, "cancelled")

    Timecop.freeze(experiment_start_time - 1.day) do
      @control_group.enroll(@control_patient)
      @single_message_group.enroll(@single_message_patient)
      @cascade_group.enroll(@cascade_patient)
    end
  end

  describe "patient_data_aggregate" do
    it "aggregates data for all experiment patients" do
      subject = described_class.new(@experiment)
      results = subject.patient_data_aggregate

      expected_control_patient_result = {
        "Experiment Name" => @experiment.name,
        "Treatment Group" => @control_group.description,
        "Experiment Inclusion Date" => @control_patient.treatment_group_memberships.first.created_at.to_date,
        "Followups" =>
          [{"Experiment Appointment 1 Date" => @control_appt_1.scheduled_date.to_date,
            "Followup 1 Date" => @control_followup_1.device_created_at.to_date,
            "Days to visit 1" => @control_appt_1_followup_days},
            {
              "Experiment Appointment 2 Date" => @control_appt_2.scheduled_date.to_date,
              "Followup 2 Date" => nil,
              "Days to visit 2" => nil
            }],
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
        "Patient Risk Level" => @control_patient.high_risk? ? "High" : "Normal",
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
        "Followups" =>
           [{"Days to visit 1" => @smp_appt_followup_days,
             "Experiment Appointment 1 Date" => @smp_appt.scheduled_date.to_date,
             "Followup 1 Date" => @smp_followup_1.device_created_at.to_date}],
        "Appointments" =>
         [{"Appointment 1 Creation Date" => @smp_appt.device_created_at.to_date,
           "Appointment 1 Date" => @smp_appt.scheduled_date.to_date}],
        "Blood Pressures" =>
         [{"Blood Pressure 1 Date" => @smp_past_visit_1.device_created_at.to_date},
           {"Blood Pressure 2 Date" => @smp_followup_1.device_created_at.to_date}],
        "Communications" => [{"Message 1 Type" => @smp_communication.communication_type,
                              "Message 1 Date Sent" => @smp_communication.detailable.delivered_on.to_date,
                              "Message 1 Status" => @smp_communication.detailable.result,
                              "Message 1 Text Identifier" => @smp_notification.message}],
        "Patient Gender" => @single_message_patient.gender,
        "Patient Age" => @single_message_patient.age,
        "Patient Risk Level" => @single_message_patient.high_risk? ? "High" : "Normal",
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
        "Followups" =>
          [{"Days to visit 1" => nil,
            "Experiment Appointment 1 Date" => @cascade_patient_appt.scheduled_date.to_date,
            "Followup 1 Date" => nil}],
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
        "Patient Risk Level" => @cascade_patient.high_risk? ? "High" : "Normal",
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

  describe "#write_csv" do
    it "returns a csv with the expected data" do
      expected_file_contents = %(Experiment Name,Treatment Group,Experiment Inclusion Date,\
Experiment Appointment 1 Date,Followup 1 Date,Days to visit 1,Experiment Appointment 2 Date,Followup 2 Date,\
Days to visit 2,Appointment 1 Creation Date,Appointment 1 Date,Appointment 2 Creation Date,Appointment 2 Date,\
Blood Pressure 1 Date,Blood Pressure 2 Date,Blood Pressure 3 Date,Message 1 Type,Message 1 Date Sent,Message 1 Status,\
Message 1 Text Identifier,Message 2 Type,Message 2 Date Sent,Message 2 Status,Message 2 Text Identifier,\
Message 3 Type,Message 3 Date Sent,Message 3 Status,Message 3 Text Identifier,Message 4 Type,Message 4 Date Sent,\
Message 4 Status,Message 4 Text Identifier,Patient Gender,Patient Age,Patient Risk Level,Assigned Facility Name,\
Assigned Facility Type,Assigned Facility State,Assigned Facility District,Assigned Facility Block,\
Patient Registration Date,Patient Id\nexportable,control,2020-12-31,2021-01-08,2021-01-10,2,2021-01-15,,,2020-12-25,\
2021-01-08,2020-12-25,2021-01-15,2020-05-01,2020-10-01,2021-01-10,,,,,,,,,,,,,,,,,female,60,Normal,Bangalore Clinic,\
City,Karnataka,South,Red Zone,2020-01-01,#{@control_patient.treatment_group_memberships.last.id}\nexportable,\
single message,2020-12-31,2021-01-15,2021-01-18,3,,,,2020-12-25,2021-01-15,,,2020-07-01,2021-01-18,,whatsapp,\
2021-01-14,read,single group message,,,,,,,,,,,,,male,70,Normal,Goa Clinic,Village,Goa,South,Blue Zone,2020-01-01,\
#{@single_message_patient.treatment_group_memberships.last.id}\nexportable,cascade,2020-12-31,2021-01-22,,,,,,\
2020-12-25,2021-01-22,,,2020-11-01,,,whatsapp,2021-01-21,failed,cascade 1,sms,2021-01-21,delivered,cascade 1,\
whatsapp,2021-01-22,failed,cascade 2,sms,2021-01-22,delivered,cascade 2,female,50,Normal,Bangalore Clinic,City,\
Karnataka,South,Red Zone,2020-01-01,#{@cascade_patient.treatment_group_memberships.last.id}\n)

      expect(File).to receive(:write).with("/tmp/#{@experiment.name}.csv", expected_file_contents)
      described_class.new(@experiment).write_csv
    end
  end
end
