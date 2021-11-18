require "rails_helper"

RSpec.describe Experimentation::NotificationsExperiment, type: :model do
  describe "scopes" do
    context "experiment state" do
      it "is notifying while the experiment is running" do
        experiment = create(:experiment, :with_treatment_group_and_template, :running)

        expect(described_class.notifying.pluck(:id)).to contain_exactly(experiment.id)
      end

      it "is not notifying if no reminder templates are present in the experiment" do
        create(:experiment, :with_treatment_group, :running)

        expect(described_class.notifying.pluck(:id)).to be_empty
      end

      it "is notifying only when notifications need to be sent" do
        create(:experiment, :with_treatment_group_and_template, :upcoming, name: "upcoming")
        create(:experiment, :with_treatment_group_and_template, :monitoring, name: "monitoring")
        create(:experiment, :with_treatment_group_and_template, :completed, name: "completed")
        create(:experiment, :with_treatment_group_and_template, :cancelled, start_time: 5.months.ago, end_time: 4.months.ago, name: "cancelled")
        notifying_experiment = create(:experiment, start_time: 3.day.ago, end_time: 1.day.ago, experiment_type: "current_patients", name: "yesy")

        treatment_group_1 = create(:treatment_group, experiment: notifying_experiment)
        create(:reminder_template, message: "1", treatment_group: treatment_group_1, remind_on_in_days: 0)
        create(:reminder_template, message: "2", treatment_group: treatment_group_1, remind_on_in_days: 2)
        create(:reminder_template, message: "3", treatment_group: treatment_group_1, remind_on_in_days: 3)

        not_notifying_experiment = create(:experiment, start_time: 3.day.ago, end_time: 2.day.ago, experiment_type: "stale_patients", name: "no")
        treatment_group_2 = create(:treatment_group, experiment: not_notifying_experiment)

        create(:reminder_template, message: "1", treatment_group: treatment_group_2, remind_on_in_days: 1)
        create(:reminder_template, message: "2", treatment_group: treatment_group_2, remind_on_in_days: 0)

        expect(described_class.notifying.pluck(:id)).to contain_exactly(notifying_experiment.id)
      end
    end
  end

  describe "#notifying?" do
    it "is true from start date until after all the reminders have been sent out for patients enrolled on the last day" do
      expectations = [
        {remind_on_dates: [0, 1, 2], notifying_until_after_end_date: 2.days},
        {remind_on_dates: [0, 3], notifying_until_after_end_date: 3.days},
        {remind_on_dates: [1, 2], notifying_until_after_end_date: 1.days},
        {remind_on_dates: [-1, 1], notifying_until_after_end_date: 2.days},
        {remind_on_dates: [-1, 0, 2], notifying_until_after_end_date: 3.days}
      ]

      expectations.each do |expectation|
        experiment = create(:experiment, start_time: Date.today, end_time: 2.days.from_now)
        treatment_group = create(:treatment_group, experiment: experiment)

        expectation[:remind_on_dates].each do |remind_on_date|
          create(:reminder_template,
            message: SecureRandom.uuid,
            treatment_group: treatment_group,
            remind_on_in_days: remind_on_date)
        end

        notifying_until_date = experiment.end_time + expectation[:notifying_until_after_end_date]

        Timecop.freeze(experiment.start_time - 1.day) { expect(described_class.find(experiment.id).notifying?).to eq false }
        Timecop.freeze(experiment.start_time) { expect(described_class.find(experiment.id).notifying?).to eq true }
        Timecop.freeze(notifying_until_date - 1.day) { expect(described_class.find(experiment.id).notifying?).to eq true }
        Timecop.freeze(notifying_until_date) { expect(described_class.find(experiment.id).notifying?).to eq true }
        Timecop.freeze(notifying_until_date + 1.day) { expect(described_class.find(experiment.id).notifying?).to eq false }

        experiment.cancel
      end
    end
  end

  describe ".conduct_daily" do
    it "calls enroll, monitor and schedule notifications on experiments" do
      create(:experiment, :with_treatment_group_and_template, :running, experiment_type: "current_patients")
      experiment = Experimentation::CurrentPatientExperiment.first
      expect_any_instance_of(experiment.class).to receive :enroll_patients
      expect_any_instance_of(experiment.class).to receive :monitor
      expect_any_instance_of(experiment.class).to receive :schedule_notifications

      experiment.class.conduct_daily(Date.today)
    end
  end

  describe ".eligible_patients" do
    it "doesn't include patients from a running experiment" do
      experiment = create(:experiment, start_time: 1.day.ago, end_time: 1.day.from_now)
      treatment_group = create(:treatment_group, experiment: experiment)

      patient = create(:patient, age: 18)
      not_enrolled_patient = create(:patient, age: 18)

      treatment_group.enroll(patient)

      expect(described_class.eligible_patients).not_to include(patient)
      expect(described_class.eligible_patients).to include(not_enrolled_patient)
    end

    it "includes patients from experiments that ended before 14 days" do
      experiment = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient, age: 18)
      treatment_group.enroll(patient)

      expect(described_class.eligible_patients).to include(patient)
    end

    it "doesn't include patients from experiments that ended within 14 days" do
      experiment = create(:experiment, start_time: 30.days.ago, end_time: 10.days.ago)
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient, age: 18)
      treatment_group.enroll(patient)

      expect(described_class.eligible_patients).not_to include(patient)
    end

    it "doesn't include patients are in a future experiment" do
      future_experiment = create(:experiment, start_time: 10.days.from_now, end_time: 20.days.from_now)
      future_treatment_group = create(:treatment_group, experiment: future_experiment)

      patient = create(:patient, age: 18)

      future_treatment_group.enroll(patient)

      expect(described_class.eligible_patients).not_to include(patient)
    end

    it "doesn't include patients who were once in a completed experiment but are now in a running experiment" do
      running_experiment = create(:experiment, start_time: 1.day.ago, end_time: 1.day.from_now)
      old_experiment = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      running_treatment_group = create(:treatment_group, experiment: running_experiment)
      old_treatment_group = create(:treatment_group, experiment: old_experiment)

      patient = create(:patient, age: 18)

      old_treatment_group.enroll(patient)
      running_treatment_group.enroll(patient)

      expect(described_class.eligible_patients).not_to include(patient)
    end

    it "doesn't include patients twice if they were in multiple experiments that ended" do
      experiment_1 = create(:experiment, start_time: 10.days.ago, end_time: 5.days.ago)
      experiment_2 = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      treatment_group_1 = create(:treatment_group, experiment: experiment_1)
      treatment_group_2 = create(:treatment_group, experiment: experiment_2)

      patient = create(:patient, age: 18)

      treatment_group_1.enroll(patient)
      treatment_group_2.enroll(patient)

      expect(described_class.eligible_patients).not_to include(patient)
    end

    it "excludes any patients who have multiple scheduled appointments" do
      excluded_patient = create(:patient, age: 18)
      create_list(:appointment, 2, patient: excluded_patient, status: :scheduled)

      included_patient = create(:patient, age: 18)
      create(:appointment, patient: included_patient, status: :scheduled)

      expect(described_class.eligible_patients).not_to include(excluded_patient)
      expect(described_class.eligible_patients).to include(included_patient)
    end
  end

  describe "#enroll_patients" do
    it "assigns eligible_patients to treatment groups" do
      patients = Patient.where(id: create_list(:patient, 2, age: 18))
      create(:experiment, :with_treatment_group, experiment_type: "current_patients")
      allow_any_instance_of(Experimentation::CurrentPatientExperiment).to receive(:eligible_patients).and_return(patients)

      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today)

      expect(Experimentation::CurrentPatientExperiment.first.treatment_group_memberships.pluck(:patient_id)).to match_array(patients.pluck(:id))
    end

    it "records reporting data for patients" do
      patient = create(:patient)
      create(:appointment, patient: patient, status: :scheduled)
      create(:experiment, :with_treatment_group, experiment_type: "current_patients")
      allow_any_instance_of(Experimentation::CurrentPatientExperiment).to receive(:eligible_patients).and_return(Patient.where(id: patient.id))

      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today)

      expect(Experimentation::CurrentPatientExperiment.first.treatment_group_memberships.first.slice(
        :gender,
        :age,
        :risk_level,
        :diagnosed_htn,
        :experiment_inclusion_date,
        :expected_return_date,
        :expected_return_facility_id,
        :expected_return_facility_type,
        :expected_return_facility_name,
        :expected_return_facility_block,
        :expected_return_facility_district,
        :expected_return_facility_state,
        :appointment_id,
        :appointment_creation_time,
        :appointment_creation_facility_id,
        :appointment_creation_facility_type,
        :appointment_creation_facility_name,
        :appointment_creation_facility_block,
        :appointment_creation_facility_district,
        :appointment_creation_facility_state,
        :assigned_facility_id,
        :assigned_facility_name,
        :assigned_facility_type,
        :assigned_facility_block,
        :assigned_facility_district,
        :assigned_facility_state,
        :registration_facility_id,
        :registration_facility_name,
        :registration_facility_type,
        :registration_facility_block,
        :registration_facility_district,
        :registration_facility_state
      ).values).to all be_present
    end

    it "enrolls a patient even if assigned/registration facility was discarded, no scheduled appointments are present" do
      patient = create(:patient)
      create(:experiment, :with_treatment_group, experiment_type: "current_patients")
      allow_any_instance_of(Experimentation::CurrentPatientExperiment).to receive(:eligible_patients).and_return(Patient.where(id: patient.id))

      patient.assigned_facility.discard

      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today)
      expect(Experimentation::CurrentPatientExperiment.first.treatment_group_memberships.first.assigned_facility_name).to be_nil
      expect(Experimentation::CurrentPatientExperiment.first.treatment_group_memberships.first.registration_facility_name).to be_nil
      expect(Experimentation::CurrentPatientExperiment.first.treatment_group_memberships.first.expected_return_date).to be_nil
    end

    it "enrolls max patients per day only even if called multiple times" do
      patients = create_list(:patient, 2, age: 18)
      patients.each { |patient| create(:appointment, scheduled_date: Date.today, patient: patient) }
      experiment = create(:experiment, experiment_type: "current_patients", max_patients_per_day: 1)
      treatment_group = create(:treatment_group, experiment: experiment)
      create(:reminder_template, message: "1", treatment_group: treatment_group, remind_on_in_days: 0)

      expect(Experimentation::CurrentPatientExperiment.first.eligible_patients(Date.today).count).to eq(2)
      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today, 1)
      expect(Experimentation::TreatmentGroupMembership.count).to eq(1)
      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today, 1)
      expect(Experimentation::TreatmentGroupMembership.count).to eq(1)
    end

    it "sets the expected_return_date to the expected appointment's remind_on if it is present" do
      overdue_patient = create(:patient)
      remind_on_patient = create(:patient)
      create(:experiment, :with_treatment_group, experiment_type: "current_patients")
      allow_any_instance_of(Experimentation::CurrentPatientExperiment).to receive(:eligible_patients).and_return(Patient.where(id: [overdue_patient, remind_on_patient].map(&:id)))

      appointment_scheduled_date = 100.days.ago.to_date
      remind_on_date = 70.days.ago.to_date
      create(:appointment, status: :scheduled, scheduled_date: appointment_scheduled_date, patient: overdue_patient)
      create(:appointment, status: :scheduled, scheduled_date: appointment_scheduled_date, remind_on: remind_on_date, patient: remind_on_patient)
      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today)
      overdue_patient_membership = Experimentation::TreatmentGroupMembership.find_by(patient_id: overdue_patient.id)
      remind_on_patient_membership = Experimentation::TreatmentGroupMembership.find_by(patient_id: remind_on_patient.id)

      expect(overdue_patient_membership.expected_return_date).to eq(appointment_scheduled_date)
      expect(remind_on_patient_membership.expected_return_date).to eq(remind_on_date)
    end
  end

  describe "#schedule_notifications" do
    it "creates a notification for each eligible membership to notify and records it in treatment group memberships" do
      create(:experiment, experiment_type: "current_patients")
      experiment = Experimentation::CurrentPatientExperiment.first
      treatment_group = create(:treatment_group, experiment: experiment)
      create(:reminder_template, message: "1", treatment_group: treatment_group, remind_on_in_days: 0)
      create(:reminder_template, message: "2", treatment_group: treatment_group, remind_on_in_days: 0)
      patient = create(:patient)
      create(:appointment, scheduled_date: Date.today, status: :scheduled, patient: patient)
      experiment.enroll_patients(Date.today)

      experiment.schedule_notifications(Date.today)
      expect(Notification.pluck(:patient_id)).to contain_exactly(patient.id, patient.id) # Once for each reminder template
      expect(Experimentation::TreatmentGroupMembership.pluck(:messages).map(&:keys)).to contain_exactly(["1", "2"])
    end

    it "doesn't create duplicate notifications if a notification has already been created" do
      create(:experiment, experiment_type: "current_patients")
      experiment = Experimentation::CurrentPatientExperiment.first
      treatment_group = create(:treatment_group, experiment: experiment)
      template = create(:reminder_template, treatment_group: treatment_group)
      patient = create(:patient)
      create(:appointment, scheduled_date: Date.today, status: :scheduled, patient: patient)
      experiment.enroll_patients(Date.today)
      existing_notification = create(:notification, experiment: experiment, patient: patient, reminder_template: template)

      experiment.schedule_notifications(Date.today)

      expect(Notification.all).to contain_exactly(existing_notification)
    end
  end

  describe "#record_notification_statuses" do
    it "records a result for all notifications that were recorded 'pending'" do
      patient = create(:patient)
      experiment = described_class.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      reminder_template = create(:reminder_template, message: "hello.set01", treatment_group: treatment_group)
      notification = create(:notification,
        purpose: :experimental_appointment_reminder,
        message: reminder_template.message,
        patient: patient,
        subject: nil)
      membership = create(:treatment_group_membership, treatment_group: treatment_group, patient: patient)
      membership.record_notification(notification)

      successful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :delivered, communication: successful_communication)

      unsuccessful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.message]).to include(
        {
          notification_status: "sent",
          result: "success",
          successful_communication_id: successful_communication.id,
          successful_communication_type: successful_communication.communication_type,
          successful_communication_created_at: successful_communication.created_at.to_s,
          successful_delivery_status: "delivered"
        }.with_indifferent_access
      )
    end

    it "records a failure if only failed deliveries are present" do
      patient = create(:patient)
      experiment = described_class.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      reminder_template = create(:reminder_template, message: "hello.set01", treatment_group: treatment_group)
      notification = create(:notification,
        purpose: :experimental_appointment_reminder,
        message: reminder_template.message,
        patient: patient,
        subject: nil)
      membership = create(:treatment_group_membership, treatment_group: treatment_group, patient: patient)
      membership.record_notification(notification)

      unsuccessful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.message]).to include(
        {
          notification_status: notification.status,
          result: "failed"
        }.with_indifferent_access
      )
    end

    it "doesn't record a result failure if no deliveries are present" do
      patient = create(:patient)
      experiment = described_class.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      reminder_template = create(:reminder_template, message: "hello.set01", treatment_group: treatment_group)
      notification = create(:notification,
        purpose: :experimental_appointment_reminder,
        message: reminder_template.message,
        patient: patient,
        subject: nil)
      membership = create(:treatment_group_membership, treatment_group: treatment_group, patient: patient)
      membership.record_notification(notification)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.message]).to include(
        {
          notification_status: notification.status,
          notification_status_updated_at: notification.updated_at.iso8601(3)
        }.with_indifferent_access
      )
    end

    it "records notification statuses for all memberships (not just enrolled)" do
      patient = create(:patient)
      experiment = described_class.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      reminder_template = create(:reminder_template, message: "hello.set01", treatment_group: treatment_group)
      notification = create(:notification,
        purpose: :experimental_appointment_reminder,
        message: reminder_template.message,
        patient: patient,
        subject: nil)
      membership = create(:treatment_group_membership, treatment_group: treatment_group, status: :evicted, patient: patient)
      membership.record_notification(notification)

      successful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :delivered, communication: successful_communication)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.message]).to include({notification_status: notification.status, result: "success"}.with_indifferent_access)
    end

    it "doesn't fail for discarded patients" do
      patient = create(:patient)
      experiment = described_class.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      reminder_template = create(:reminder_template, message: "hello.set01", treatment_group: treatment_group)
      notification = create(:notification,
        purpose: :experimental_appointment_reminder,
        message: reminder_template.message,
        patient: patient,
        subject: nil)
      membership = create(:treatment_group_membership, treatment_group: treatment_group, status: :evicted, patient: patient)
      membership.record_notification(notification)
      patient.discard_data

      experiment.record_notification_results
    end
  end

  describe "#cancel" do
    it "changes pending and scheduled notification statuses to 'cancelled'" do
      experiment = create(:experiment)
      patient = create(:patient)

      pending_notification = create(:notification, experiment: experiment, patient: patient, status: "pending")
      scheduled_notification = create(:notification, experiment: experiment, patient: patient, status: "scheduled")
      sent_notification = create(:notification, experiment: experiment, patient: patient, status: "sent")

      described_class.first.cancel

      expect(pending_notification.reload.status).to eq("cancelled")
      expect(scheduled_notification.reload.status).to eq("cancelled")
      expect(sent_notification.reload.status).to eq("sent")
    end
  end

  describe "mark_visits" do
    it "considers earliest BP created as a visit for enrolled patients" do
      membership = create(:treatment_group_membership, status: :enrolled, experiment_inclusion_date: 10.days.ago)
      experiment = described_class.find(membership.experiment.id)

      patient = membership.patient
      _old_bp = create(:blood_pressure, recorded_at: 20.days.ago, patient: patient)
      _old_bs = create(:blood_sugar, recorded_at: 20.days.ago, patient: patient)

      _discarded_bp = create(:blood_pressure, recorded_at: 10.days.ago, patient: patient, deleted_at: Time.current)
      bp_1 = create(:blood_pressure, recorded_at: 6.days.ago, patient: patient)
      _bp_2 = create(:blood_pressure, recorded_at: 5.days.ago, patient: patient)

      bs_1 = create(:blood_sugar, recorded_at: 6.days.ago, patient: patient)
      _bs_2 = create(:blood_sugar, recorded_at: 5.days.ago, patient: patient)

      _drug = create(:prescription_drug, device_created_at: 6.days.ago, patient: patient)

      experiment.mark_visits
      membership.reload

      expect(membership.visit_blood_pressure_id).to eq(bp_1.id)
      expect(membership.visit_blood_sugar_id).to eq(bs_1.id)
      expect(membership.visit_prescription_drug_created).to eq(true)
    end

    it "cancels all pending notifications for evicted patients" do
      membership = create(:treatment_group_membership, status: :visited)
      patient = membership.patient
      experiment = described_class.find(membership.experiment.id)

      pending_notification = create(:notification, patient: patient, status: :pending, experiment: experiment)
      scheduled_notification = create(:notification, patient: patient, status: :scheduled, experiment: experiment)
      _non_experiment_notification = create(:notification, patient: patient, status: :scheduled)

      experiment.mark_visits

      expect(Notification.status_cancelled).to contain_exactly(pending_notification, scheduled_notification)
    end
  end

  describe "#evict_patients" do
    it "evicts patients who have another scheduled appointment created since enrollment" do
      patient = create(:patient)
      appointment = create(:appointment, status: :scheduled, patient: patient)
      other_patient = create(:patient)
      experiment = Experimentation::NotificationsExperiment.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      treatment_group.enroll(patient, appointment_id: appointment.id)
      treatment_group.enroll(other_patient)
      _new_scheduled_appointment = create(:appointment, status: :scheduled, patient: patient)

      experiment.evict_patients

      expect(experiment.treatment_group_memberships.status_enrolled.pluck(:patient_id)).to contain_exactly(other_patient.id)
      expect(experiment.treatment_group_memberships.status_evicted.pluck(:patient_id)).to contain_exactly(patient.id)
    end

    it "evicts patients whose appointment is not scheduled anymore" do
      patient = create(:patient)
      appointment = create(:appointment, status: :scheduled, patient: patient)
      experiment = Experimentation::NotificationsExperiment.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      treatment_group.enroll(patient, appointment_id: appointment.id)
      appointment.update(status: :visited)

      experiment.evict_patients

      expect(experiment.treatment_group_memberships.status_enrolled.count).to eq 0
      expect(experiment.treatment_group_memberships.status_evicted.pluck(:patient_id)).to contain_exactly(patient.id)
    end

    it "evicts patients whose appointment has been marked with a remind_on after the expected_return_date" do
      patient = create(:patient)
      appointment = create(:appointment, status: :scheduled, patient: patient)
      experiment = Experimentation::NotificationsExperiment.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      treatment_group.enroll(patient, appointment_id: appointment.id, expected_return_date: 5.days.from_now)
      appointment.update(remind_on: 10.days.from_now)

      experiment.evict_patients

      expect(experiment.treatment_group_memberships.status_enrolled.count).to eq 0
      expect(experiment.treatment_group_memberships.status_evicted.pluck(:patient_id)).to contain_exactly(patient.id)
    end

    it "does not evict patients who were enrolled with remind_on as the expected_return_date" do
      patient = create(:patient)
      remind_on_date = 70.days.ago
      appointment = create(:appointment, status: :scheduled, scheduled_date: 100.days.ago, remind_on: remind_on_date, patient: patient)
      experiment = Experimentation::NotificationsExperiment.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      treatment_group.enroll(patient, appointment_id: appointment.id, expected_return_date: remind_on_date)

      experiment.evict_patients

      expect(experiment.treatment_group_memberships.status_enrolled.pluck(:patient_id)).to contain_exactly(patient.id)
      expect(experiment.treatment_group_memberships.status_evicted.count).to eq 0
    end

    it "evicts patients whose notification has failed" do
      patient = create(:patient)
      appointment = create(:appointment, status: :scheduled, patient: patient)
      experiment = Experimentation::NotificationsExperiment.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      create(:reminder_template, treatment_group: treatment_group, message: "hello.set01")
      membership = treatment_group.enroll(patient, appointment_id: appointment.id, messages: {})

      membership.messages["hello.set01"] = {result: :failed}
      membership.save!

      experiment.evict_patients

      expect(experiment.treatment_group_memberships.status_enrolled.count).to eq 0
      expect(experiment.treatment_group_memberships.status_evicted.pluck(:patient_id)).to contain_exactly(patient.id)
    end

    it "evicts patients whose notification has failed" do
      patient = create(:patient)
      appointment = create(:appointment, status: :scheduled, patient: patient)
      experiment = Experimentation::NotificationsExperiment.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      create(:reminder_template, treatment_group: treatment_group, message: "hello.set01")
      membership = treatment_group.enroll(patient, appointment_id: appointment.id, messages: {})

      membership.messages["hello.set01"] = {result: :failed}
      membership.save!

      experiment.evict_patients

      expect(experiment.treatment_group_memberships.status_enrolled.count).to eq 0
      expect(experiment.treatment_group_memberships.status_evicted.pluck(:patient_id)).to contain_exactly(patient.id)
    end

    it "evicts patients who have been soft deleted" do
      patient = create(:patient)
      appointment = create(:appointment, status: :scheduled, patient: patient)
      experiment = Experimentation::NotificationsExperiment.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      create(:reminder_template, treatment_group: treatment_group, message: "hello.set01")
      _membership = treatment_group.enroll(patient, appointment_id: appointment.id, messages: {})
      patient.discard

      experiment.evict_patients

      expect(experiment.treatment_group_memberships.status_enrolled.count).to eq 0
      expect(experiment.treatment_group_memberships.status_evicted.pluck(:patient_id)).to contain_exactly(patient.id)
    end

    it "cancels all pending notifications for evicted patients" do
      membership = create(:treatment_group_membership, status: :evicted)
      patient = membership.patient
      experiment = described_class.find(membership.experiment.id)

      pending_notification = create(:notification, patient: patient, status: :pending, experiment: experiment)
      scheduled_notification = create(:notification, patient: patient, status: :scheduled, experiment: experiment)
      _non_experiment_notification = create(:notification, patient: patient, status: :scheduled)

      experiment.evict_patients

      expect(Notification.status_cancelled).to contain_exactly(pending_notification, scheduled_notification)
    end
  end

  describe "#time" do
    it "calls statsd instance time" do
      expect(Statsd.instance).to receive(:time).with("current_patients.monitor")

      create(:experiment)
      described_class.first.monitor
    end
  end
end
