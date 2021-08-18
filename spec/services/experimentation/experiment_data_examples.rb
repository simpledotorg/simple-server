RSpec.shared_context "active experiment data", :shared_context => :metadata do
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
    experiment_start_date = Date.parse("January 1, 2021")
    experiment_end_date = Date.parse("January 31, 2021")
    first_week_of_experiment = experiment_start_date + 1.week
    second_week_of_experiment = experiment_start_date + 2.weeks
    third_week_of_experiment = experiment_start_date + 3.weeks
    week_before_experiment = experiment_start_date - 1.week

    @experiment = create(:experiment, name: "exportable", experiment_type: "current_patients", start_date: experiment_start_date, end_date: experiment_end_date)
    @control_group = create(:treatment_group, experiment: @experiment, description: "control")
    @single_message_group = create(:treatment_group, experiment: @experiment, description: "single message")
    @single_template = create(:reminder_template, treatment_group: @single_message_group, remind_on_in_days: -1, message: "single group message")
    @cascade_group = create(:treatment_group, experiment: @experiment, description: "cascade group")
    @cascade_template1 = create(:reminder_template, treatment_group: @single_message_group, remind_on_in_days: -1, message: "cascade 1")
    @cascade_template2 = create(:reminder_template, treatment_group: @single_message_group, remind_on_in_days: 0, message: "cascade 2")
    @cascade_template3 = create(:reminder_template, treatment_group: @single_message_group, remind_on_in_days: 3, message: "cascade 3")

    @control_patient = create(:patient)
    @control_appt1 = create(:appointment, patient: @control_patient, scheduled_date: first_week_of_experiment, device_created_at: week_before_experiment)
    @control_followup_1 = create(:blood_pressure, patient: @control_patient, device_created_at: first_week_of_experiment + 2.days)
    @control_appt2 = create(:appointment, patient: @control_patient, scheduled_date: second_week_of_experiment, device_created_at: week_before_experiment)
    _control_followup_2 = create(:blood_sugar, patient: @control_patient, device_created_at: second_week_of_experiment + 1.day)
    @control_past_visit_1 = create(:blood_pressure, patient: @control_patient, device_created_at: experiment_start_date - 8.months)
    @control_past_visit_2 = create(:blood_pressure, patient: @control_patient, device_created_at: experiment_start_date - 3.months)
    _control_past_visit_2_bs = create(:blood_sugar, patient: @control_patient, device_created_at: experiment_start_date - 2.months)

    @single_message_patient = create(:patient)
    @smp_appt1 = create(:appointment, patient: @single_message_patient, scheduled_date: second_week_of_experiment)
    _smp_followup_pd = create(:prescription_drug, patient: @single_message_patient, device_created_at: second_week_of_experiment)
    @smp_notification = create_notification(@experiment, @single_template, @single_message_patient, @smp_appt1, "sent")
    @smp_communication = create(:communication, notification: @smp_notification, communication_type: "whatsapp")
    create(:twilio_sms_delivery_detail, communication: @smp_communication, delivered_on: @smp_notification.remind_on, result: "read")
    @smp_past_visit_1 = create(:blood_pressure, patient: @single_message_patient, device_created_at: experiment_start_date - 6.months)
    _smp_past_visit_1_pd = create(:prescription_drug, patient: @single_message_patient, device_created_at: experiment_start_date - 6.months)

    @cascade_patient = create(:patient)
    @cascade_patient_appt = create(:appointment, patient: @cascade_patient, scheduled_date: third_week_of_experiment)
    @cascade_notification1 = create_notification(@experiment, @cascade_template1, @cascade_patient, @cascade_patient_appt, "sent")
    @cascade_comm1 = create(:communication, notification: @cascade_notification1, communication_type: "whatsapp")
    create(:twilio_sms_delivery_detail, communication: @cascade_comm1, delivered_on: @cascade_notification1.remind_on, result: "failed")
    @cascade_comm2 = create(:communication, notification: @cascade_notification1, communication_type: "sms")
    create(:twilio_sms_delivery_detail, communication: @cascade_comm2, delivered_on: @cascade_notification1.remind_on, result: "delivered")
    @cascade_notification2 = create_notification(@experiment, @cascade_template2, @cascade_patient, @cascade_patient_appt, "sent")
    @cascade_comm3 = create(:communication, notification: @cascade_notification2, communication_type: "whatsapp")
    create(:twilio_sms_delivery_detail, communication: @cascade_comm3, delivered_on: @cascade_notification2.remind_on, result: "failed")
    @cascade_comm4 = create(:communication, notification: @cascade_notification2, communication_type: "sms")
    create(:twilio_sms_delivery_detail, communication: @cascade_comm4, delivered_on: @cascade_notification2.remind_on, result: "delivered")
    _cascade_notification3 = create_notification(@experiment, @cascade_template3, @cascade_patient, @cascade_patient_appt, "cancelled")

    Timecop.freeze(experiment_start_date - 1.day) do
      @control_group.patients << @control_patient
      @single_message_group.patients << @single_message_patient
      @cascade_group.patients << @cascade_patient
    end
  end
end