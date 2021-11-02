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

      it "is notifying after all the reminders have been sent out for patients enrolled on the last day" do
        create(:experiment, :with_treatment_group_and_template, :upcoming)
        create(:experiment, :with_treatment_group_and_template, :monitoring)
        create(:experiment, :with_treatment_group_and_template, :completed)
        create(:experiment, :with_treatment_group_and_template, :cancelled, start_time: 5.months.ago, end_time: 4.months.ago)
        notifying_experiment = create(:experiment, start_time: 3.day.ago, end_time: 1.day.ago, experiment_type: "current_patients")

        treatment_group_1 = create(:treatment_group, experiment: notifying_experiment)
        create(:reminder_template, message: "1", treatment_group: treatment_group_1, remind_on_in_days: 0)
        create(:reminder_template, message: "2", treatment_group: treatment_group_1, remind_on_in_days: 2)
        create(:reminder_template, message: "3", treatment_group: treatment_group_1, remind_on_in_days: 3)

        not_notifying_experiment = create(:experiment, start_time: 3.day.ago, end_time: 1.day.ago, experiment_type: "stale_patients")
        treatment_group_2 = create(:treatment_group, experiment: not_notifying_experiment)

        create(:reminder_template, message: "1", treatment_group: treatment_group_2, remind_on_in_days: 1)
        create(:reminder_template, message: "2", treatment_group: treatment_group_2, remind_on_in_days: 0)

        expect(described_class.notifying.pluck(:id)).to contain_exactly(notifying_experiment.id)
      end
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
      experiment = create(:experiment, experiment_type: "current_patients")
      treatment_group = create(:treatment_group, experiment: experiment)
      create(:reminder_template, message: "1", treatment_group: treatment_group, remind_on_in_days: 0)
      stub_const("#{Experimentation::NotificationsExperiment}::MAX_PATIENTS_PER_DAY", 1)

      expect(Experimentation::CurrentPatientExperiment.first.eligible_patients(Date.today).count).to eq(2)
      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today, 1)
      expect(Experimentation::TreatmentGroupMembership.count).to eq(1)
      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today, 1)
      expect(Experimentation::TreatmentGroupMembership.count).to eq(1)
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
      experiment = described_class.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      reminder_template = create(:reminder_template, message: "hello.set01", treatment_group: treatment_group)
      notification = create(:notification, message: reminder_template.message)
      membership = create(:treatment_group_membership, treatment_group: treatment_group)
      membership.record_notification(notification)

      successful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :delivered, communication: successful_communication)

      unsuccessful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.message]).to include(
        {
          status: notification.status,
          result: "success",
          successful_communication_type: successful_communication.communication_type,
          successful_communication_created_at: successful_communication.created_at.to_s,
          delivery_status: "delivered"
        }.with_indifferent_access
      )
    end

    it "records a failure if only failed deliveries are present" do
      experiment = described_class.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      reminder_template = create(:reminder_template, message: "hello.set01", treatment_group: treatment_group)
      notification = create(:notification, message: reminder_template.message)
      membership = create(:treatment_group_membership, treatment_group: treatment_group)
      membership.record_notification(notification)

      unsuccessful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.message]).to include(
        {
          status: notification.status,
          result: "failed"
        }.with_indifferent_access
      )
    end

    it "records notification statuses for all memberships (not just enrolled)" do
      experiment = described_class.find(create(:experiment).id)
      treatment_group = create(:treatment_group, experiment: experiment)
      reminder_template = create(:reminder_template, message: "hello.set01", treatment_group: treatment_group)
      notification = create(:notification, message: reminder_template.message)
      membership = create(:treatment_group_membership, treatment_group: treatment_group, status: :evicted)
      membership.record_notification(notification)

      successful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :delivered, communication: successful_communication)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.message]).to include({ status: notification.status, result: "success"}.with_indifferent_access)
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
end
