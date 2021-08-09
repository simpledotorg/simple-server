module Experimentation
  class DataExport

    attr_reader :experiment, :max_communications, :max_appointments, :max_encounters, :notification_start_date

    def initialize(name)
      @experiment = Experimentation::Experiment.find_by!(name: name)
      remind_ons = experiment.reminder_templates.pluck(:remind_on_in_days)
      @notification_start_date = experiment.start_date - remind_ons.min.days
      @max_communications = 0
      @max_appointments = 0
      @max_encounters = 0
    end

    def results
      data = aggregate_data
      # fill in expandable data sets
      adjust_communications_length(data)
      adjust_appointments_length(data)
      adjust_encounters_length(data)
      headers = create_headers(data)
      # make csv
      return { headers: headers, data: data.map{|patient_data| patient_data.values.flatten }}
    end

    private

    def aggregate_data
      data = []
      experiment.treatment_groups.each do |group|
        group.patients.each do |patient|
          tgm = patient.treatment_group_memberships.find_by(treatment_group_id: group.id)
          notifications = patient.notifications.where(experiment_id: experiment.id).order(:remind_on)
          assigned_facility = patient.assigned_facility

          data << {
            experiment_name: experiment.name,
            treatment_group: group.description,
            experiment_inclusion_date: tgm.created_at.to_date,
            appointments: process_appointments(patient, notifications),
            encounters: process_past_visits(patient),
            communications: process_communications(notifications),
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

    def process_communications(notifications)
      communications = notifications.each_with_object([]) do |n, ary|
        ordered_communications = n.communications.sort_by{|c| c.created_at }
        ordered_communications.each do |c|
          ary << [c.communication_type, c.detailable&.delivered_on, c.detailable&.result]
        end
      end

      @max_communications = communications.count if communications.count > @max_communications
      communications
    end

    def process_appointments(patient, notifications)
      appts = notifications.map(&:subject).uniq.sort_by{|appt| appt.scheduled_date }
      @max_appointments = appts.count if appts.count > max_appointments

      encounters_during_experiment = encounters(patient, notification_start_date, Date.current)
      appts.each_with_index.map do |appt, i|
        corresponding_encounter_date = encounters_during_experiment[i - 1]
        days_til_visit = nil
        bp_at_visit = nil
        if corresponding_encounter_date
          days_til_visit = appt.scheduled_date - corresponding_encounter_date
          bp_at_visit = patient.blood_pressures.find_by(device_created_at: corresponding_encounter_date)
        end
        [appt.device_created_at.to_date, appt.scheduled_date, days_til_visit, bp_at_visit]
      end
    end

    def process_past_visits(patient)
      end_date = notification_start_date - 1.day
      start_date = end_date - 1.year
      encounters = encounters(patient, start_date, end_date)
      @max_encounters = encounters.count if encounters.count > max_encounters
      encounters
    end

    def encounters(patient, start_date, end_date)
      bps = patient.blood_pressures.where(device_created_at: (experiment.start_date - 1.year)..Date.current).pluck(:device_created_at).map(&:to_date)
      bss = patient.blood_sugars.where(device_created_at: (experiment.start_date - 1.year)..Date.current).pluck(:device_created_at).map(&:to_date)
      pds = patient.prescription_drugs.where(device_created_at: (experiment.start_date - 1.year)..Date.current).pluck(:device_created_at).map(&:to_date)
      encounters = (bps + bss + pds).uniq.sort
    end

    def adjust_communications_length(data)
      data.each do |patient_data|
        fillers_needed = @max_communications - patient_data[:communications].count
        fillers_needed.times do
           patient_data[:communications] << [nil, nil, nil]
        end
      end
    end

    def adjust_appointments_length(data)
      data.each do |patient_data|
        fillers_needed = @max_appointments - patient_data[:appointments].count
        fillers_needed.times do
          patient_data[:appointments] << [nil, nil, nil, nil]
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
        when :communications
          @max_communications.times do |i|
            headers << "Message #{i} Type"
            headers << "Message #{i} Sent"
            headers << "Message #{i} Status"
          end
        when :appointments
          @max_appointments.times do |i|
            headers << "Appointment #{i} Creation Date"
            headers << "Appointment #{i} Date"
            headers << "Days to visit #{i}"
            headers << "BP recorded at visit #{i}"
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