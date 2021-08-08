module Experimentation
  class DataExport

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
      adjust_encounters_length(data)
      headers = create_headers(data)
      # make csv
      return {headers: headers, data: data.map(&:values)}
    end

    private

    def aggregate_data
      data = []
      experiment.treatment_groups.each do |group|
        group.patients.each do |patient|
          tgm = patient.treatment_group_memberships.find_by(treatment_group_id: group.id)
          notifications = patient.notifications.where(experiment_id: experiment.id)
          @max_notifications = notifications.count if notifications.count > @max_notifications
          assigned_facility = patient.assigned_facility

          data << {
            experiment_name: experiment.name,
            treatment_group: group.description,
            experiment_inclusion_date: tgm.created_at,
            appointments: process_appointments(notifications),
            encounters: encounters(patient),
            notifications: process_notifications(notifications),
            bp_recorded_at_visit: "bp recorded at visit", ###
            patient_gender: patient.gender,
            patient_age: patient.age,
            patient_risk_level: patient.risk_priority,
            diagnosed_hypertensive: "aren't all of these patients diagnosed hypertensive?", ###
            patient_has_phone: "don't all these patients have a phone?", ###
            encounter_date: "encounter date",
            encounter_facility_type: "encounter facility type",
            encounter_facility_state: "encounter facility state",
            encounter_facility_district: "encounter facility district",
            encounter_block: "encounter block",
            assigned_facility_name: assigned_facility&.name,
            assigned_facility_type: assigned_facility&.facility_type,
            assigned_facility_state: assigned_facility&.state,
            assigned_facility_district: assigned_facility&.district,
            assigned_facility_block: assigned_facility&.block,
            patient_registration_date: patient.device_created_at.to_date,
            patient_id: tgm.id
          }
        end
      end
      data
    end

    def process_notifications(notifications)
      notifications.each_with_object([]) do |n, obj|
        next if n.communications.empty?
        communication = n.communications.order(created_at: :desc).last
        obj << { message_type: communication.communication_type, message_sent: communication&.detailable&.delivered_on, message_status: communication&.detailable&.result }
      end
    end

    def process_appointments(notifications)
      appts = notifications.map(&:subject).uniq
      @max_appointments = appts.count if appts.count > max_appointments
      appts.map do |appt|
        { appointment_creation_date: appt.device_created_at.to_date, appointment_date: appt.scheduled_date }
      end
    end

    def encounters(patient)
      bps = patient.blood_pressures.where(device_created_at: (experiment.start_date - 1.year)..Date.current).pluck(:device_created_at).map(&:to_date)
      bss = patient.blood_sugars.where(device_created_at: (experiment.start_date - 1.year)..Date.current).pluck(:device_created_at).map(&:to_date)
      pds = patient.prescription_drugs.where(device_created_at: (experiment.start_date - 1.year)..Date.current).pluck(:device_created_at).map(&:to_date)
      encounters = (bps + bss + pds).uniq.sort
      @max_encounters = encounters.count if encounters.count > max_encounters
      encounters
    end

    def adjust_notifications_length(data)
      data.each do |patient_data|
        (@max_notifications - patient_data[:notifications].count).times do
           patient_data[:notifications] << { message_type: nil, message_sent: nil, message_status: nil }
        end
      end
    end

    def adjust_appointments_length(data)
      data.each do |patient_data|
        (@max_appointments - patient_data[:appointments].count).times do
          patient_data[:appointments] << { appointment_creation_date: nil, appointment_date: nil }
        end
      end
    end

    def adjust_encounters_length(data)
      data.each do |patient_data|
        (@max_encounters - patient_data[:encounters].count).times { patient_data[:encounters] << nil }
      end
    end

    def create_headers(data)
      keys = data.first.keys
      keys.each_with_object([]) do |k, headers|
        case k
        when :notifications
          @max_notifications.times do |i|
            headers << "Message #{i} Type"
            headers << "Message #{i} Sent"
            headers << "Message #{i} Status"
          end
        when :appointments
          @max_appointments.times do |i|
            headers << "Appointment #{i} Creation Date"
            headers << "Appointment #{i} Date"
          end
        when :encounters
          @max_encounters.times do |i|
            headers << "Encounter #{i} Date"
          end
        else
          headers << k.to_s.split("_").each(&:capitalize!).join(" ")
        end
      end
    end
  end
end