module Experimentation
  class NotificationsExperiment < Experiment
    include ActiveSupport::Benchmarkable
    BATCH_SIZE = 1000

    default_scope { where(experiment_type: %w[current_patients stale_patients]) }

    def self.notifying
      all.select { |experiment| experiment.notifying? }
    end

    def notifying?
      return false unless reminder_templates.exists?

      notification_buffer = (last_remind_on - earliest_remind_on).days
      notify_until = (end_time + notification_buffer).to_date
      start_time <= Date.current && notify_until >= Date.current
    end

    # The order of operations is important.
    # See https://docs.google.com/document/d/1IMXu_ca9xKU8Xox_3v403ZdvNGQzczLWljy7LQ6RQ6A for more details.
    def self.conduct_daily(date)
      time(__method__) do
        running.each { |experiment| experiment.enroll_patients(date) }
        monitoring.each { |experiment| experiment.monitor }
        notifying.each { |experiment| experiment.schedule_notifications(date) }
      end
    end

    # Returns patients who are eligible for enrollment. These should be
    # filtered further by individual notification experiments based on their criteria.
    def self.eligible_patients
      Patient.with_hypertension
        .contactable
        .joins(:assigned_facility)
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
        .then { |patients| exclude_bangladesh_blocks(patients) }
    end

    def self.exclude_bangladesh_blocks(patients)
      return patients unless CountryConfig.current_country?("Bangladesh")

      patients
        .merge(Facility.with_block_region_id)
        .select("patients.*")
        .where.not(block_region: {id: excluded_block_ids.presence})
    end

    def self.excluded_block_ids
      ENV.fetch("EXPERIMENT_EXCLUDED_BLOCKS", "").split(",").map(&:strip)
    end

    def enroll_patients(date, limit = max_patients_per_day)
      time(__method__) do
        eligible_patients(date)
          .limit([remaining_enrollments_allowed(date), limit].min)
          .includes(:assigned_facility, :registration_facility, :medical_history)
          .includes(latest_scheduled_appointments: [:facility, :creation_facility])
          .in_batches(of: BATCH_SIZE)
          .each_record { |patient| random_treatment_group.enroll(patient, reporting_data(patient, date)) }
      end
    end

    def monitor
      time(__method__) do
        record_notification_results
        mark_visits
        evict_patients
      end
    end

    def record_notification_results
      # TODO: Look at query performance
      time(__method__) do
        treatment_group_memberships
          .joins(:patient, treatment_group: :reminder_templates)
          .where("messages -> reminder_templates.message ->> 'notification_status' = ?", :pending)
          .select("messages -> reminder_templates.message ->> 'notification_id' AS notification_id")
          .select("reminder_templates.message, treatment_group_memberships.*")
          .in_batches(of: BATCH_SIZE).each_record do |membership|
          membership.record_notification_result(
            membership.message,
            notification_result(membership.notification_id)
          )
        end
      end
    end

    def evict_patients
      time(__method__) do
        treatment_group_memberships.status_enrolled
          .joins(:appointment)
          .where("appointments.status <> 'scheduled' or appointments.remind_on > expected_return_date")
          .evict(reason: "appointment_moved")

        treatment_group_memberships.status_enrolled
          .joins(patient: :latest_scheduled_appointments)
          .where("treatment_group_memberships.appointment_id <> appointments.id")
          .evict(reason: "new_appointment_created_after_enrollment")

        treatment_group_memberships.status_enrolled
          .joins(treatment_group: :reminder_templates)
          .where("messages -> reminder_templates.message ->> 'result' = 'failed'")
          .evict(reason: "notification_failed")

        treatment_group_memberships.status_enrolled
          .where(patient_id: Patient.with_discarded.discarded)
          .evict(reason: "patient_soft_deleted")

        cancel_evicted_notifications
      end
    end

    def mark_visits
      time(__method__) do
        treatment_group_memberships
          .joins(:patient)
          .where("treatment_group_memberships.status = 'enrolled' OR
                  (treatment_group_memberships.status = 'evicted' AND
                   visited_at IS NULL)")
          .select("distinct on (treatment_group_memberships.patient_id) treatment_group_memberships.*,
                 bp.id bp_id, bs.id bs_id, pd.id pd_id")
          .joins("left outer join blood_pressures bp
          on bp.patient_id = treatment_group_memberships.patient_id
          and bp.recorded_at > experiment_inclusion_date
          and bp.deleted_at is null")
          .joins("left outer join blood_sugars bs
          on bs.patient_id = treatment_group_memberships.patient_id
          and bs.recorded_at > experiment_inclusion_date
          and bs.deleted_at is null")
          .joins("left outer join prescription_drugs pd
          on pd.patient_id = treatment_group_memberships.patient_id
          and pd.device_created_at > experiment_inclusion_date
          and pd.deleted_at is null")
          .where("coalesce(bp.id, bs.id, pd.id) is not null")
          .order("treatment_group_memberships.patient_id, bp.recorded_at, bs.recorded_at, pd.device_created_at")
          .each do |membership|
          membership.record_visit(
            blood_pressure: membership.bp_id && BloodPressure.find(membership.bp_id),
            blood_sugar: membership.bs_id && BloodSugar.find(membership.bs_id),
            prescription_drug: membership.pd_id && PrescriptionDrug.find(membership.pd_id)
          )
        end

        cancel_visited_notifications
      end
    end

    def schedule_notifications(date)
      time(__method__) do
        memberships_to_notify(date)
          .select("reminder_templates.id reminder_template_id")
          .select("reminder_templates.message message, treatment_group_memberships.*")
          .in_batches(of: BATCH_SIZE)
          .each_record { |membership| schedule_notification(membership, date) }
      end
    end

    def cancel
      ActiveRecord::Base.transaction do
        notifications.cancel
        super
      end
    end

    def self.time(method_name, &block)
      raise ArgumentError, "You must supply a block" unless block

      label = "#{name}.#{method_name}"

      benchmark(label) do
        Statsd.instance.time(label) do
          yield(block)
        end
      end

      Statsd.instance.flush # The metric is not sent to datadog until the buffer is full, hence we explicitly flush.
    end

    delegate :time, to: self

    def earliest_remind_on
      reminder_templates.pluck(:remind_on_in_days).min || 0
    end

    def last_remind_on
      reminder_templates.pluck(:remind_on_in_days).max || 0
    end

    private

    def remaining_enrollments_allowed(date)
      max_patients_per_day - treatment_group_memberships.where(experiment_inclusion_date: date).count
    end

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
        expected_return_date: latest_scheduled_appointment&.remind_on || latest_scheduled_appointment&.scheduled_date,
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

    def notification_result(notification_id)
      notification = Notification.find(notification_id)

      case notification.delivery_result
        when :success
          successful_delivery = notification.successful_deliveries.first

          {notification_status: notification.status,
           notification_status_updated_at: notification.updated_at,
           result: :success,
           successful_communication_id: successful_delivery.id,
           successful_communication_type: successful_delivery.communication_type,
           successful_communication_created_at: successful_delivery.created_at.to_s,
           successful_delivery_status: successful_delivery.result}
        when :failed
          {notification_status: notification.status,
           notification_status_updated_at: notification.updated_at,
           result: :failed}
        else
          {notification_status: notification.status,
           notification_status_updated_at: notification.updated_at}
      end
    end

    def cancel_evicted_notifications
      notifications
        .where(patient_id: treatment_group_memberships.status_evicted.select(:patient_id))
        .cancel
    end

    def cancel_visited_notifications
      notifications
        .where(patient_id: treatment_group_memberships.status_visited.select(:patient_id))
        .cancel
    end

    def schedule_notification(membership, date)
      Notification.where(
        experiment: self,
        reminder_template_id: membership.reminder_template_id,
        patient_id: membership.patient_id
      ).exists? ||
        Notification.create!(
          experiment: self,
          message: membership.message,
          patient_id: membership.patient_id,
          purpose: :experimental_appointment_reminder,
          remind_on: date,
          reminder_template_id: membership.reminder_template_id,
          status: "pending",
          subject_id: membership.appointment_id,
          subject_type: membership.appointment_id.present? ? "Appointment" : nil
        ).then { |notification| membership.record_notification(notification) }
    end
  end
end
