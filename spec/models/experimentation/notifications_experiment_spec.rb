require "rails_helper"

RSpec.describe Experimentation::NotificationsExperiment, type: :model do
  describe "scopes" do
    context "experiment state" do
      it "is notifying while the experiment is enrolling" do
        experiment = create(:experiment, :with_treatment_group_and_template, :enrolling)

        expect(described_class.notifying.pluck(:id)).to contain_exactly(experiment.id)
      end

      it "is not notifying if no reminder templates are present in the experiment" do
        create(:experiment, :with_treatment_group, :enrolling)

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
    it "is true regardless of what time of day the start_time and end_time of the experiment are set to" do
      experiment_1 = create(:experiment, start_time: Date.today.middle_of_day, end_time: 2.days.from_now.middle_of_day)
      create(:reminder_template, treatment_group: create(:treatment_group, experiment: experiment_1))
      Timecop.freeze(experiment_1.start_time.beginning_of_day) { expect(described_class.find(experiment_1.id).notifying?).to eq true }
      experiment_1.cancel

      experiment_2 = create(:experiment, start_time: Date.today.end_of_day, end_time: 2.days.from_now.middle_of_day)
      treatment_group_2 = create(:treatment_group, experiment: experiment_2)
      create(:reminder_template, treatment_group: treatment_group_2)
      Timecop.freeze(experiment_2.start_time.beginning_of_day) { expect(described_class.find(experiment_2.id).notifying?).to eq true }
      experiment_2.cancel

      experiment_3 = create(:experiment, start_time: Date.today.beginning_of_day, end_time: 2.days.from_now.middle_of_day)
      treatment_group_3 = create(:treatment_group, experiment: experiment_3)
      create(:reminder_template, treatment_group: treatment_group_3)
      Timecop.freeze(experiment_3.end_time.beginning_of_day) { expect(described_class.find(experiment_3.id).notifying?).to eq true }
      Timecop.freeze(experiment_3.end_time.end_of_day) { expect(described_class.find(experiment_3.id).notifying?).to eq true }
      experiment_3.cancel
    end
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
      create(:experiment, :with_treatment_group_and_template, :enrolling, experiment_type: "current_patients")
      experiment = Experimentation::CurrentPatientExperiment.first
      expect_any_instance_of(experiment.class).to receive :enroll_patients
      expect_any_instance_of(experiment.class).to receive :monitor
      expect_any_instance_of(experiment.class).to receive :schedule_notifications

      experiment.class.conduct_daily(Date.today)
    end
  end

  describe ".eligible_patients" do
    it "doesn't include patients from an active experiment" do
      experiment = create(:experiment, start_time: 1.day.ago, end_time: 1.day.from_now)
      treatment_group = create(:treatment_group, experiment: experiment)

      enrolled_patient = create(:patient, age: 18)
      not_enrolled_patient = create(:patient, age: 18)

      treatment_group.enroll(enrolled_patient)

      expect(described_class.eligible_patients).not_to include(enrolled_patient)
      expect(described_class.eligible_patients).to include(not_enrolled_patient)
    end

    it "includes patients who were in an experiment before the monitoring buffer (15 days)" do
      experiment_1 = create(:experiment, start_time: 30.days.ago, end_time: 10.days.ago)
      treatment_group = create(:treatment_group, experiment: experiment_1)
      patient = create(:patient, age: 18)
      Timecop.freeze(16.days.ago) { treatment_group.enroll(patient) }

      expect(described_class.eligible_patients).to include(patient)
    end

    it "doesn't include a patient who is being monitored currently by another experiment" do
      experiment = create(:experiment, start_time: 20.days.ago, end_time: 10.days.ago)
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient, age: 18)
      Timecop.freeze(12.days.ago) { treatment_group.enroll(patient) }

      expect(described_class.eligible_patients).not_to include(patient)
    end

    it "doesn't include patients who are in a future experiment" do
      future_experiment = create(:experiment, start_time: 10.days.from_now, end_time: 20.days.from_now)
      future_treatment_group = create(:treatment_group, experiment: future_experiment)

      patient = create(:patient, age: 18)

      future_treatment_group.enroll(patient)

      expect(described_class.eligible_patients).not_to include(patient)
    end

    it "doesn't include patients who were once in a completed experiment but are now in an active experiment" do
      active_experiment = create(:experiment, start_time: 1.day.ago, end_time: 1.day.from_now)
      old_experiment = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      active_treatment_group = create(:treatment_group, experiment: active_experiment)
      old_treatment_group = create(:treatment_group, experiment: old_experiment)

      patient = create(:patient, age: 18)

      old_treatment_group.enroll(patient)
      active_treatment_group.enroll(patient)

      expect(described_class.eligible_patients).not_to include(patient)
    end

    it "doesn't include patients twice if they were in multiple experiments that ended" do
      experiment_1 = create(:experiment, start_time: 29.days.ago, end_time: 20.days.ago)
      experiment_2 = create(:experiment, start_time: 60.days.ago, end_time: 30.days.ago)

      treatment_group_1 = create(:treatment_group, experiment: experiment_1)
      treatment_group_2 = create(:treatment_group, experiment: experiment_2)

      patient = create(:patient, age: 18)

      Timecop.freeze(25.days.ago) { treatment_group_1.enroll(patient) }
      Timecop.freeze(50.days.ago) { treatment_group_2.enroll(patient) }

      expect(described_class.eligible_patients).to contain_exactly(patient)
    end

    it "doesn't include any patients whose assigned facility has been deleted" do
      excluded_patient = create(:patient, age: 18)
      excluded_patient.assigned_facility.discard

      included_patient = create(:patient, age: 18)
      create(:appointment, patient: included_patient, status: :scheduled)

      expect(described_class.eligible_patients).not_to include(excluded_patient)
      expect(described_class.eligible_patients).to include(included_patient)
    end

    it "excludes patients who are excluded in the filters" do
      facility1 = create(:facility)
      patient1 = create(:patient, age: 18, assigned_facility: facility1)

      facility2 = create(:facility, state: "Excluded State")
      patient2 = create(:patient, age: 18, assigned_facility: facility2)

      facility3 = create(:facility)
      patient3 = create(:patient, age: 18, assigned_facility: facility3)

      filters = {
        "states" => {"exclude" => ["Excluded State"]},
        "blocks" => {"exclude" => [facility3.block_region.id]},
        "facilities" => {"exclude" => [facility1.slug]}
      }

      eligible_patient = create(:patient, age: 18)

      expect(described_class.eligible_patients(filters)).not_to include(patient1, patient2, patient3)
      expect(described_class.eligible_patients).to include(eligible_patient)
    end

    it "includes patients who are included in the filters" do
      facility1 = create(:facility, state: "Test State")
      patient1 = create(:patient, age: 18, assigned_facility: facility1)

      excluded_facility1 = create(:facility, state: "Test State")
      excluded_patient1 = create(:patient, age: 18, assigned_facility: excluded_facility1)

      excluded_facility2 = create(:facility)
      excluded_patient2 = create(:patient, age: 18, assigned_facility: excluded_facility2)

      filters = {
        "states" => {"include" => [facility1.state]},
        "blocks" => {"include" => [facility1.block_region.id]},
        "facilities" => {"include" => [facility1.slug]}
      }

      expect(described_class.eligible_patients(filters)).to include(patient1)
      expect(described_class.eligible_patients(filters)).not_to include(excluded_patient1, excluded_patient2)
    end
  end

  describe "#enroll_patients" do
    it "assigns eligible_patients to treatment groups" do
      patients = Patient.where(id: create_list(:patient, 2, age: 18))
      create(:experiment, :with_treatment_group, experiment_type: "current_patients")

      date = Date.today
      filters = {"states" => {"exclude" => ["Non Existent State"]}}
      expect_any_instance_of(Experimentation::CurrentPatientExperiment).to receive(:eligible_patients).with(date, filters).and_return(patients)

      Experimentation::CurrentPatientExperiment.first.enroll_patients(date, filters)

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

    it "does not raise an exception and continues with other patients if a patient is tried to enrolled more than once" do
      patient = create(:patient)
      create(:experiment, :with_treatment_group, experiment_type: "current_patients")
      allow_any_instance_of(Experimentation::CurrentPatientExperiment).to receive(:eligible_patients).and_return(Patient.where(id: patient.id))

      exception = ActiveRecord::RecordNotUnique.new('duplicate key value violates unique constraint "index_tgm_patient_id_and_experiment_id"')
      allow_any_instance_of(Experimentation::TreatmentGroup).to receive(:enroll).and_raise(exception)

      expect { Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today) }.not_to raise_exception
    end

    it "does not suppress exceptions other than multiple enrollment for the same patient" do
      patient = create(:patient)
      create(:experiment, :with_treatment_group, experiment_type: "current_patients")
      allow_any_instance_of(Experimentation::CurrentPatientExperiment).to receive(:eligible_patients).and_return(Patient.where(id: patient.id))

      allow_any_instance_of(Experimentation::TreatmentGroup).to receive(:enroll).and_raise(StandardError)

      expect { Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today) }.to raise_exception(StandardError)
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

      expect(Experimentation::CurrentPatientExperiment.first.eligible_patients(Date.today).size).to eq(2)
      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today, {}, 1)
      expect(Experimentation::TreatmentGroupMembership.count).to eq(1)
      Experimentation::CurrentPatientExperiment.first.enroll_patients(Date.today, {}, 1)
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

    context "when local date is not the same as utc date" do
      it "sets experiment_inclusion_date to local date when local is ahead of utc by 1 day" do
        create(:experiment, :with_treatment_group, experiment_type: "current_patients")
        current_experiment = Experimentation::CurrentPatientExperiment.first
        enrollment_date_dhaka = Date.parse("28 Jul 2023")
        expected_inclusion_date_dhaka = Date.parse("28 Jul 2023")

        # Bangladesh is 6 hours ahead of UTC. We expect the experiment_inclusion_date
        # to be the same both before and after 6am BDT (12am UTC).

        patient_1 = create(:patient)
        allow(current_experiment).to receive(:eligible_patients).and_return(Patient.where(id: patient_1.id))
        Time.use_zone("Asia/Dhaka") do
          Timecop.freeze("5:59am") { current_experiment.enroll_patients(enrollment_date_dhaka) }
        end
        membership_1 = current_experiment.treatment_group_memberships.find_by(patient_id: patient_1.id)
        expect(membership_1.experiment_inclusion_date.to_date).to eq(expected_inclusion_date_dhaka)

        patient_2 = create(:patient)
        allow(current_experiment).to receive(:eligible_patients).and_return(Patient.where(id: patient_2.id))
        Time.use_zone("Asia/Dhaka") do
          Timecop.freeze("6:01am") { current_experiment.enroll_patients(enrollment_date_dhaka) }
        end
        membership_2 = current_experiment.treatment_group_memberships.find_by(patient_id: patient_2.id)
        expect(membership_2.experiment_inclusion_date.to_date).to eq(expected_inclusion_date_dhaka)
      end

      it "sets experiment_inclusion_date to local date when local is behind utc by 1 day" do
        create(:experiment, :with_treatment_group, experiment_type: "current_patients")
        current_experiment = Experimentation::CurrentPatientExperiment.first
        enrollment_date_ny = Date.parse("27 Jul 2023")
        expected_inclusion_date_ny = Date.parse("27 Jul 2023")

        # New York is 4 hours behind UTC. We expect the experiment_inclusion_date
        # to be the same both before and after 8pm EDT (12am UTC).

        patient_1 = create(:patient)
        allow(current_experiment).to receive(:eligible_patients).and_return(Patient.where(id: patient_1.id))
        Time.use_zone("America/New_York") do
          Timecop.freeze("8:01pm") { current_experiment.enroll_patients(enrollment_date_ny) }
        end
        membership_1 = current_experiment.treatment_group_memberships.find_by(patient_id: patient_1.id)
        expect(membership_1.experiment_inclusion_date.to_date).to eq(expected_inclusion_date_ny)

        patient_2 = create(:patient)
        allow(current_experiment).to receive(:eligible_patients).and_return(Patient.where(id: patient_2.id))
        Time.use_zone("America/New_York") do
          Timecop.freeze("7:59pm") { current_experiment.enroll_patients(enrollment_date_ny) }
        end
        membership_2 = current_experiment.treatment_group_memberships.find_by(patient_id: patient_2.id)
        expect(membership_2.experiment_inclusion_date.to_date).to eq(expected_inclusion_date_ny)
      end

      it "sets expected_return_date to local date when the local tz is off from utc by 1 day" do
        create(:experiment, :with_treatment_group, experiment_type: "current_patients")
        current_experiment = Experimentation::CurrentPatientExperiment.first
        enrollment_date = Date.parse("28 Jul 2023")

        # expected_return_date is set to the latest appointment's scheduled_date
        # or remind_on date values.
        # We expect it to be set to the correct date both before and after UTC date
        # changes over the course of the given local date, when the experiment is run.

        patient_1 = create(:patient)
        appointment_1 = create(:appointment, status: :scheduled, patient: patient_1)
        expected_return_date_1 = appointment_1.scheduled_date
        allow(current_experiment).to receive(:eligible_patients).and_return(Patient.where(id: patient_1.id))
        Time.use_zone("Asia/Dhaka") do
          Timecop.freeze("5:59am") { current_experiment.enroll_patients(enrollment_date) }
        end
        membership_1 = current_experiment.treatment_group_memberships.find_by(patient_id: patient_1.id)
        expect(membership_1.expected_return_date.to_date).to eq(expected_return_date_1)

        patient_2 = create(:patient)
        appointment_2 = create(:appointment, status: :scheduled, patient: patient_2)
        expected_return_date_2 = appointment_2.scheduled_date
        allow(current_experiment).to receive(:eligible_patients).and_return(Patient.where(id: patient_2.id))
        Time.use_zone("Asia/Dhaka") do
          Timecop.freeze("6:01am") { current_experiment.enroll_patients(enrollment_date) }
        end
        membership_2 = current_experiment.treatment_group_memberships.find_by(patient_id: patient_2.id)
        expect(membership_2.expected_return_date.to_date).to eq(expected_return_date_2)
      end
    end
  end

  describe "#schedule_notifications" do
    it "creates a notification for each eligible membership to notify and records it in treatment group memberships" do
      create(:experiment, experiment_type: "current_patients")
      experiment = Experimentation::CurrentPatientExperiment.first
      treatment_group = create(:treatment_group, experiment: experiment)
      template_1 = create(:reminder_template, message: "1", treatment_group: treatment_group, remind_on_in_days: 0)
      template_2 = create(:reminder_template, message: "2", treatment_group: treatment_group, remind_on_in_days: 0)
      patient = create(:patient)
      create(:appointment, scheduled_date: Date.today, status: :scheduled, patient: patient)
      experiment.enroll_patients(Date.today)

      experiment.schedule_notifications(Date.today)
      expect(Notification.pluck(:patient_id)).to contain_exactly(patient.id, patient.id) # Once for each reminder template
      expect(Experimentation::TreatmentGroupMembership.pluck(:messages).flat_map(&:keys)).to contain_exactly(template_1.id, template_2.id)
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
      membership.record_notification(reminder_template.id, notification)

      successful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :delivered, communication: successful_communication)

      unsuccessful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.id]).to include(
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
      membership.record_notification(reminder_template.id, notification)

      unsuccessful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.id]).to include(
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
      membership.record_notification(reminder_template.id, notification)
      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.id]).to include(
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
      membership.record_notification(reminder_template.id, notification)

      successful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :delivered, communication: successful_communication)

      experiment.record_notification_results

      expect(membership.reload.messages[reminder_template.id]).to include({notification_status: notification.status, result: "success"}.with_indifferent_access)
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
      membership.record_notification(reminder_template.id, notification)
      patient.discard_data(reason: :duplicate)

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
    it "considers earliest BP, BS or drug created as a visit for enrolled patients" do
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

    it "considers earliest BP, BS or drug created as a visit for evicted patients and does not change status" do
      membership = create(:treatment_group_membership, status: :evicted, status_reason: "evicted", experiment_inclusion_date: 10.days.ago)
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
      expect(membership.status).to eq("evicted")
      expect(membership.status_reason).to eq("evicted")
    end

    it "doesn't mark visits for discarded patients" do
      membership = create(:treatment_group_membership, status: :enrolled, experiment_inclusion_date: 10.days.ago)
      experiment = described_class.find(membership.experiment.id)

      patient = membership.patient
      _old_bp = create(:blood_pressure, recorded_at: 20.days.ago, patient: patient)
      _old_bs = create(:blood_sugar, recorded_at: 20.days.ago, patient: patient)

      create(:blood_pressure, recorded_at: 6.days.ago, patient: patient)
      create(:blood_pressure, recorded_at: 5.days.ago, patient: patient)
      patient.discard

      experiment.mark_visits
      membership.reload

      expect(membership.visit_blood_pressure_id).to be_nil
      expect(membership.visit_prescription_drug_created).to eq(nil)
      expect(membership.status).to eq("enrolled")
    end

    it "cancels all pending notifications for visited patients" do
      membership = create(:treatment_group_membership, status: :visited)
      patient = membership.patient
      experiment = described_class.find(membership.experiment.id)

      pending_notification = create(:notification, patient: patient, status: :pending, experiment: experiment)
      scheduled_notification = create(:notification, patient: patient, status: :scheduled, experiment: experiment)
      _non_experiment_notification = create(:notification, patient: patient, status: :scheduled)

      experiment.mark_visits

      expect(Notification.status_cancelled).to contain_exactly(pending_notification, scheduled_notification)
    end

    context "for patients who are in experiments which start one after the other" do
      it "both their visits should be tracked separately" do
        experiment_1 = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
        experiment_2 = create(:experiment, start_time: 14.days.ago, end_time: 1.day.ago)

        treatment_group_1 = create(:treatment_group, experiment: experiment_1)
        treatment_group_2 = create(:treatment_group, experiment: experiment_2)

        patient = create(:patient, age: 18)

        experiment_1_membership = treatment_group_1.enroll(patient, {experiment_inclusion_date: 26.days.ago})
        experiment_2_membership = treatment_group_2.enroll(patient, {experiment_inclusion_date: 13.days.ago})

        bp_during_experiment_1 = create(:blood_pressure, recorded_at: 20.days.ago, patient: patient)

        Experimentation::NotificationsExperiment.find(experiment_1.id).mark_visits
        Experimentation::NotificationsExperiment.find(experiment_2.id).mark_visits

        expect(experiment_1_membership.reload.visited_at).to eq(bp_during_experiment_1.reload.recorded_at)
        expect(experiment_2_membership.reload.visited_at).to eq(nil)

        bp_during_experiment_2 = create(:blood_pressure, recorded_at: 3.days.ago, patient: patient)

        Experimentation::NotificationsExperiment.find(experiment_1.id).mark_visits
        Experimentation::NotificationsExperiment.find(experiment_2.id).mark_visits

        expect(experiment_1_membership.reload.visited_at).to eq(bp_during_experiment_1.reload.recorded_at)
        expect(experiment_2_membership.reload.visited_at).to eq(bp_during_experiment_2.reload.recorded_at)
      end
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
      template = create(:reminder_template, treatment_group: treatment_group, message: "hello.set01")
      membership = treatment_group.enroll(patient, appointment_id: appointment.id, messages: {})

      membership.messages[template.id] = {result: :failed}
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
      expect(Metrics).to receive(:benchmark_and_gauge).with("notification_experiments_tasks_duration_seconds", {task: :monitor})

      create(:experiment)
      described_class.first.monitor
    end
  end

  describe "#notification_result" do
    let(:notification) { create(:notification, status: "sent", communications: [communication]) }
    let(:communication) { create(:communication, detailable_type: detailable_type, detailable_id: detailable.id) }

    subject { described_class.new.send(:notification_result, notification.id) }

    context "with Mobitel as sms vendor" do
      let(:detailable) { create(:mobitel_delivery_detail) }
      let(:detailable_type) { "MobitelDeliveryDetail" }

      it "returns successful result" do
        expect { subject }.not_to raise_error
        actual_result = subject
        expect(actual_result[:notification_status]).to eq(notification.status)
        expect(actual_result[:successful_communication_id]).to eq(communication.id)
        expect(actual_result[:successful_communication_type]).to eq(communication.communication_type)
        expect(actual_result[:successful_delivery_status]).to eq(communication.detailable.result)
        expect(actual_result[:notification_status_updated_at].to_date).to eq(notification.updated_at.to_date)
      end
    end

    context "with AlphaSMS as vendor" do
      let(:detailable) { create(:alpha_sms_delivery_detail, request_status: "Sent") }
      let(:detailable_type) { "AlphaSmsDeliveryDetail" }

      it "returns successful result" do
        expect { subject }.not_to raise_error
        actual_result = subject
        expect(actual_result[:notification_status]).to eq(notification.status)
        expect(actual_result[:successful_communication_id]).to eq(communication.id)
        expect(actual_result[:successful_communication_type]).to eq(communication.communication_type)
        expect(actual_result[:successful_delivery_status]).to eq(communication.detailable.result)
        expect(actual_result[:notification_status_updated_at].to_date).to eq(notification.updated_at.to_date)
      end
    end

    context "with BSNL as vendor" do
      let(:detailable) { create(:bsnl_delivery_detail, message_status: "7") }
      let(:detailable_type) { "BsnlDeliveryDetail" }

      it "returns successful result" do
        expect { subject }.not_to raise_error
        actual_result = subject
        expect(actual_result[:notification_status]).to eq(notification.status)
        expect(actual_result[:successful_communication_id]).to eq(communication.id)
        expect(actual_result[:successful_communication_type]).to eq(communication.communication_type)
        expect(actual_result[:successful_delivery_status]).to eq(communication.detailable.result)
        expect(actual_result[:notification_status_updated_at].to_date).to eq(notification.updated_at.to_date)
      end
    end

    context "with Twilio as vendor" do
      let(:detailable) { create(:twilio_sms_delivery_detail, result: "sent") }
      let(:detailable_type) { "TwilioSmsDeliveryDetail" }

      it "returns successful result" do
        expect { subject }.not_to raise_error
        actual_result = subject
        expect(actual_result[:notification_status]).to eq(notification.status)
        expect(actual_result[:successful_communication_id]).to eq(communication.id)
        expect(actual_result[:successful_communication_type]).to eq(communication.communication_type)
        expect(actual_result[:successful_delivery_status]).to eq(communication.detailable.result)
        expect(actual_result[:notification_status_updated_at].to_date).to eq(notification.updated_at.to_date)
      end
    end
  end
end
