module Experimentation
  class DataExport
    require "csv"

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
      adjust_communications_length(data)
      adjust_appointments_length(data)
      adjust_encounters_length(data)
      create_csv(data)
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
            patient_gender: patient.gender,
            patient_age: patient.age,
            patient_risk_level: patient.risk_priority,
            diagnosed_hypertensive: "aren't all of these patients diagnosed hypertensive?", ###
            patient_has_phone: "don't all these patients have a phone?", ###
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

      encounters_during_experiment = encounter_dates(patient, notification_start_date, Date.current)

      appts.each_with_index.map do |appt, i|
        # just pulling out encounters sequentially because there's no formal relationship to appointments
        followup_date = encounters_during_experiment[i - 1]
        days_til_followup = nil
        bp_at_followup = nil
        facility = nil

        if followup_date
          days_til_followup = appt.scheduled_date - followup_date
          bp_at_followup = patient.blood_pressures.find_by(device_created_at: followup_date)
          encounter = encounter_by_date(patient, followup_date)
          facility = encounter.facility
        end
        [appt.device_created_at.to_date, appt.scheduled_date, followup_date, days_til_followup, bp_at_followup,
          facility&.facility_type, facility&.state, facility&.district, facility&.block]
      end
    end

    def process_past_visits(patient)
      end_date = notification_start_date - 1.day
      start_date = end_date - 1.year
      encounter_dates = encounter_dates(patient, start_date, end_date)
      @max_encounters = encounter_dates.count if encounter_dates.count > max_encounters
      encounter_dates
    end

    def encounter_dates(patient, start_date, end_date)
      date_range = (start_date.beginning_of_day..end_date.end_of_day)
      bps = patient.blood_pressures.where(device_created_at: date_range).pluck(:device_created_at).map(&:to_date)
      bss = patient.blood_sugars.where(device_created_at: date_range).pluck(:device_created_at).map(&:to_date)
      pds = patient.prescription_drugs.where(device_created_at: date_range).pluck(:device_created_at).map(&:to_date)
      encounters = (bps + bss + pds).uniq.sort
    end

    def encounter_by_date(patient, date)
      date_range = (date.beginning_of_day..date.end_of_day)
      bp = patient.blood_pressures.find_by(device_created_at: date_range)
      return bp if bp
      bs = patient.blood_sugars.find_by(device_created_at: date_range)
      return bs if bs
      pd = patient.prescription_drugs.find_by(device_created_at: date_range)
      return pd if pd
      # this shouldn't happen. consider raising error
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
          patient_data[:appointments] << [nil, nil, nil, nil, nil, nil, nil, nil, nil]
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
          (1..@max_communications).step do |i|
            headers << "Message #{i} Type"
            headers << "Message #{i} Sent"
            headers << "Message #{i} Status"
          end
        when :appointments
          (1..@max_appointments).step do |i|
            headers << "Appointment #{i} Creation Date"
            headers << "Appointment #{i} Date"
            headers << "Followup #{i} Date"
            headers << "Days to visit #{i}"
            headers << "BP recorded at visit #{i}"
            headers << "Followup #{i} Facility Type"
            headers << "Followup #{i} Facility State"
            headers << "Followup #{i} Facility District"
            headers << "Followup #{i} Facility Block"
          end
        when :encounters
          (1..@max_encounters).step do |i|
            headers << "Encounter #{i} Date"
          end
        else
          headers << k.to_s.split("_").each(&:capitalize!).join(" ")
        end
      end
    end

    def create_csv(data)
      CSV.generate(headers: true) do |csv|
        headers = create_headers(data)
        csv << headers
        data.each {|patient_data| csv << patient_data.values.flatten }
      end
    end
  end
end