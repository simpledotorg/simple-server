module Experimentation
  class DataExport

    # tell daniel: 

    HEADERS = ["Test", "Bucket", "Bucket name", "Experiment Inclusion Date", "Appointment Creation Date",
      	"Appointment Date",	"Patient Visit Date",	"Days to visit", "Message 1 Type", "Message 1 Sent", "Message 1 Received", "Message 2 Type", "Message 2 Sent",
        "Message 2 Status",	"Message 3 Type",	"Message 3 Sent",	"Message 3 Received",	"BP recorded at visit",	"Patient Gender",	"Patient Age",
        "Patient risk level",	"Diagnosed HTN", "Patient has phone number", "Patient Visited Facility", "Visited Facility Type",	"Visited Facility State",
        "Visited Facility District", "Visited Facility Block", "Patient Assigned Facility",	"Assigned Facility Type",	"Assigned Facility State",
        "Assigned Facility District", "Assigned Facility Block", "Prior visit 1",	"Prior visit 2", "Prior visit 12", "Call made 1",	"Call made 2",
        "Call made 3", "Patient registration date",	"Patient ID"]

    attr_reader :experiment, :max_notifications, :max_appointments, :max_encounters

    def initialize(name)
      @experiment = Experimentation::Experiment.find_by!(name: name)
      @max_notifications = 0
      @max_appointments = 0
      @max_encounters = 0
    end

    def results
      data = aggregate_data
      # fill in expandable data sets
      adjust_notifications_length(data)
      adjust_appointments_length(data)
      # make csv
      data
    end

    private

    def aggregate_data
      data = []
      experiment.treatment_groups.each do |group|
        group.patients.each do |patient|
          tgm = patient.treatment_group_memberships.find_by(treatment_group_id: group.id)
          notifications = patient.notifications.where(experiment_id: experiment.id)
          @max_notifications = notifications.count if notifications.count > @max_notifications

          notification_data = notifications.each_with_object([]) do |n, obj|
            next if n.communications.empty?
            communication = n.communications.order(created_at: :desc).last
            obj << [communication.communication_type, communication.detailable.delivered_on, communication.detailable.result]
          end

          appts = notifications.map(&:subject).uniq
          @max_appointments = appts.count if appts.count > max_appointments
          appointment_data = appts.map do |appt|
            [appt.device_created_at.to_date, appt.scheduled_date]
          end

          # encounter_date = Date.current # the hard part
          # days_to_visit = encounter_date - appts.first.scheduled_date

          assigned_facility = patient.assigned_facility

          data << {
            experiment_name: experiment.name,
            treatment_group: group.description,
            experiment_inclusion_date: tgm.created_at,
            appointments: appointment_data, # changed
            # encounter_date: encounter_date, # change
            # days_to_visit: days_to_visit, # change
            notifications: notification_data,
            bp_recorded_at_visit: "bp recorded at visit",
            patient_gender: patient.gender,
            patient_age: patient.age,
            patient_risk: patient.risk_priority,
            diagnosed_hypertensive: "aren't all of these patients diagnosed hypertensive?",
            has_phone: "don't all these patients have a phone?",
            encounter_date: "encounter date",
            encounter_facility_type: "encounter facility type",
            encounter_facility_state: "encounter facility state",
            encounter_facility_district: "encounter facility district",
            encounter_block: "encounter block",
            assigned_facility_name: assigned_facility&.name,
            assigned_facility_type: assigned_facility&.facility_type,
            assigned_facility_state: assigned_facility&.state,
            assigned_facility_district: assigned_facility&.district,
            assigned_facility_block: "what is a facility block?",
            patient_registration_date: patient.device_created_at.to_date,
            patient_id: tgm.id
          }
        end
      end
      data
    end

    def adjust_notifications_length(data)
      data.each do |patient|
        (@max_notifications - patient[:notifications].count).times { patient[:notifications] << [nil, nil, nil] }
      end
    end

    def adjust_appointments_length(data)
      data.each do |patient|
        (@max_appointments - patient[:appointments].count).times { patient[:appointments] << [nil, nil] }
      end
    end

    def encounters(patient)
      # rather than trying to figure out if an encounter was related to an appointment or notification
      # it might make more sense to give all encounters for the year in sequence and let the researchers figure it out
      # patient.blood_pressures.where()
    end
  end
end