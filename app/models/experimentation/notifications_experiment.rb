module Experimentation
  class NotificationsExperiment < Experiment
    include Memery
    MAX_PATIENTS_PER_DAY = 2000
    MEMBERSHIPS_BATCH_SIZE = 1000

    default_scope { where(experiment_type: %w[current_patients stale_patients]) }

    scope :notifying, -> do
      joins(treatment_groups: :reminder_templates)
        .where("start_time <= ? AND end_time + make_interval(days := remind_on_in_days) > ? ", Time.current, Time.current)
        .distinct
    end

    # The order of operations is important.
    # See https://docs.google.com/document/d/1IMXu_ca9xKU8Xox_3v403ZdvNGQzczLWljy7LQ6RQ6A for more details.
    def self.conduct_daily(date)
      running.each { |experiment| experiment.enroll_patients(date) }
      monitoring.each { |experiment| experiment.monitor(date) }
      notifying.each { |experiment| experiment.schedule_notifications(date) }
    end

    # Returns patients who are eligible for enrollment. These should be
    # filtered further by individual notification experiments based on their criteria.
    def self.eligible_patients
      Patient.with_hypertension
        .contactable
        .where_current_age(">=", 18)
        .where("NOT EXISTS (:recent_experiment_memberships)",
          recent_experiment_memberships: Experimentation::TreatmentGroupMembership
                                           .joins(treatment_group: :experiment)
                                           .where("treatment_group_memberships.patient_id = patients.id")
                                           .where("end_time > ?", RECENT_EXPERIMENT_MEMBERSHIP_BUFFER.ago)
                                           .select(:patient_id))
        .where("NOT EXISTS (:multiple_scheduled_appointments)",
          multiple_scheduled_appointments: Appointment
                                             .select(1)
                                             .where("appointments.patient_id = patients.id")
                                             .where(status: :scheduled)
                                             .group(:patient_id)
                                             .having("count(patient_id) > 1"))
    end

    def enroll_patients(date, limit = MAX_PATIENTS_PER_DAY)
      eligible_patients(date)
        .limit(limit)
        .includes(:assigned_facility, :registration_facility, :medical_history)
        .includes(latest_scheduled_appointments: [:facility, :creation_facility])
        .in_batches(of: MEMBERSHIPS_BATCH_SIZE)
        .each_record { |patient| random_treatment_group.enroll(patient, reporting_data(patient, date)) }
    end

    def monitor(date)
      report_notification_statuses
      mark_visits
      evict_patients
    end

    def schedule_notifications(date)
      reminder_templates.each do |template|
        memberships_to_notify(template, date)
          .in_batches(of: MEMBERSHIPS_BATCH_SIZE)
          .each_record { |membership| schedule_notification(membership, template, date) }
      end
    end

    def schedule_notification(membership, template, date)
      return if Notification.find_by(
        reminder_template: template,
        experiment: self,
        patient_id: membership.patient_id
      )

      notification = Notification.create!(
        experiment: self,
        message: template.message,
        patient_id: membership.patient_id,
        purpose: :experimental_appointment_reminder,
        remind_on: date,
        reminder_template: template,
        status: "pending"
      )

      membership.record_notification(notification)
    end

    def report_notification_statuses
      reminder_templates.each do |template|
        notified_memberships =
          treatment_group_memberships
            .where("messages -> #{template.message} -> status = ?", :pending)
            .select("messages -> #{template.message} -> 'notification_id' AS notification_id, *")

        notified_memberships.in_batches(of: MEMBERSHIPS_BATCH_SIZE).each_record do |membership|
          deliveries =
            Notification
              .joins("inner join communications on communications.notification_id = notifications.id")
              .joins("inner join twilio_sms_delivery_details detailable on detailable.id = communications.detailable_id")
              .select("communications.*, detailable.*,*")
              .where(membership.notification_id)

          successful_delivery = deliveries.find_by(result: [:read, :delivered, :sent])

          if successful_delivery.present?
            membership.messages[template.message].merge({
              status: successful_delivery.status,
              result: :success,
              successful_communication_type: successful_delivery.communication.communication_type,
              successful_communication_created_at: successful_delivery.communication.created_at,
              delivery_status: successful_delivery.result
            })
          else
            membership.messages[template.message].merge({
              status: deliveries.first.status,
              result: :failed
            })
          end
        end
      end
    end

    def cancel
      ActiveRecord::Base.transaction do
        notifications.where(status: %w[pending scheduled]).update_all(status: :cancelled)
        super
      end
    end

    private

    def reporting_data(patient, date)
      medical_history = patient.medical_history
      latest_scheduled_appointment = patient.latest_scheduled_appointment
      assigned_facility = patient.assigned_facility
      registration_facility = patient.registration_facility

      {
        gender: patient.gender,
        age: patient.current_age,
        risk_level: patient.risk_priority,
        diagnosed_htn: medical_history.hypertension,
        experiment_inclusion_date: date,
        expected_return_date: latest_scheduled_appointment&.scheduled_date,
        expected_return_facility_id: latest_scheduled_appointment&.facility_id,
        expected_return_facility_type: latest_scheduled_appointment&.facility&.facility_type,
        expected_return_facility_name: latest_scheduled_appointment&.facility&.name,
        expected_return_facility_block: latest_scheduled_appointment&.facility&.block,
        expected_return_facility_district: latest_scheduled_appointment&.facility&.district,
        expected_return_facility_state: latest_scheduled_appointment&.facility&.state,
        appointment_id: latest_scheduled_appointment&.id,
        appointment_creation_time: latest_scheduled_appointment&.created_at,
        appointment_creation_facility_id: latest_scheduled_appointment&.creation_facility&.id,
        appointment_creation_facility_type: latest_scheduled_appointment&.creation_facility&.facility_type,
        appointment_creation_facility_name: latest_scheduled_appointment&.creation_facility&.name,
        appointment_creation_facility_block: latest_scheduled_appointment&.creation_facility&.block,
        appointment_creation_facility_district: latest_scheduled_appointment&.creation_facility&.district,
        appointment_creation_facility_state: latest_scheduled_appointment&.creation_facility&.state,
        assigned_facility_id: patient.assigned_facility_id,
        assigned_facility_name: assigned_facility&.name,
        assigned_facility_type: assigned_facility&.facility_type,
        assigned_facility_block: assigned_facility&.block,
        assigned_facility_district: assigned_facility&.district,
        assigned_facility_state: assigned_facility&.state,
        registration_facility_id: patient.registration_facility_id,
        registration_facility_name: registration_facility&.name,
        registration_facility_type: registration_facility&.facility_type,
        registration_facility_block: registration_facility&.block,
        registration_facility_district: registration_facility&.district,
        registration_facility_state: registration_facility&.state
      }
    end

    def mark_visits
    end

    def evict_patients
    end
  end
end
