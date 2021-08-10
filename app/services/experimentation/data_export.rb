module Experimentation
  class DataExport
    require "csv"

    FOLLOWUP_CUTOFF = 10.days

    attr_reader :experiment, :max_communications, :max_appointments, :max_past_visits, :notification_start_date, :aggregate, :cutoff_date

    def initialize(name)
      @experiment = Experimentation::Experiment.find_by!(name: name)
      remind_ons = experiment.reminder_templates.pluck(:remind_on_in_days)
      @notification_start_date = experiment.start_date - remind_ons.min.days
      @max_communications = 0
      @max_appointments = 0
      @max_past_visits = 0
      @aggregate = []
      @cutoff_date = experiment.end_date + FOLLOWUP_CUTOFF
    end

    def as_csv
      aggregate_data
      pad_communications
      pad_appointments
      pad_past_visits
      create_csv
    end

    private

    def aggregate_data
      experiment.treatment_groups.each do |group|
        group.patients.each do |patient|
          tgm = patient.treatment_group_memberships.find_by(treatment_group_id: group.id)
          notifications = patient.notifications.where(experiment_id: experiment.id).order(:remind_on)
          assigned_facility = patient.assigned_facility

          aggregate << {
            experiment_name: experiment.name,
            treatment_group: group.description,
            experiment_inclusion_date: tgm.created_at.to_date,
            appointments: process_appointments(patient, notifications),
            encounters: process_past_visits(patient),
            communications: process_communications(notifications),
            patient_gender: patient.gender,
            patient_age: patient.age,
            patient_risk_level: patient.risk_priority,
            diagnosed_hypertensive: true, # remove?
            patient_has_phone: true, # remove?
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
    end

    def process_communications(notifications)
      communications = notifications.each_with_object([]) do |notification, communications_data|
        ordered_communications = notification.communications.sort_by{|c| c.created_at }
        ordered_communications.each do |c|
          communications_data << [notification.message, c.communication_type, c.detailable&.delivered_on, c.detailable&.result]
        end
      end

      @max_communications = communications.count if communications.count > @max_communications
      communications
    end

    def pad_communications
      aggregate.each do |patient_data|
        communications_deficit = @max_communications - patient_data[:communications].count
        communications_deficit.times do
          patient_data[:communications] << Array.new(4, nil)
        end
      end
    end

    def process_appointments(patient, notifications)
      appts = if notifications.any?
        notifications.map(&:subject).uniq.sort_by{|appt| appt.scheduled_date }
      else
        date_range = experiment.start_date.beginning_of_day..experiment.end_date.end_of_day
        patient.appointments.where(scheduled_date: date_range).where("device_created_at < ?", notification_start_date).order(:scheduled_date)
      end
      @max_appointments = appts.count if appts.count > max_appointments

      encounters_during_experiment = encounter_dates(patient, notification_start_date, cutoff_date)

      appts.each_with_index.map do |appt, index|
        # pulling out encounters sequentially because there's no formal relationship to appointments
        followup_date = encounters_during_experiment[index]
        days_til_followup = nil
        bp_at_followup = nil
        facility = nil

        if followup_date
          days_til_followup = (appt.scheduled_date - followup_date).to_i
          encounter = encounter_by_date(patient, followup_date)
          bp_at_followup = encounter.class == BloodPressure
          facility = encounter.facility
        end
        [appt.device_created_at.to_date, appt.scheduled_date, followup_date, days_til_followup, bp_at_followup,
         facility&.name, facility&.facility_type, facility&.state, facility&.district, facility&.block]
      end
    end

    def pad_appointments
      aggregate.each do |patient_data|
        appointments_deficit = @max_appointments - patient_data[:appointments].count
        appointments_deficit.times do
          patient_data[:appointments] << Array.new(10, nil)
        end
      end
    end

    def process_past_visits(patient)
      end_date = notification_start_date - 1.day
      start_date = end_date - 1.year
      encounter_dates = encounter_dates(patient, start_date, end_date)
      @max_past_visits = encounter_dates.count if encounter_dates.count > max_past_visits
      encounter_dates
    end

    def pad_past_visits
      aggregate.each do |patient_data|
        past_visits_deficit = @max_past_visits - patient_data[:encounters].count
        past_visits_deficit.times { patient_data[:encounters] << nil }
      end
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

    def headers
      keys = aggregate.first.keys
      keys.each_with_object([]) do |key, collection|
        case key
        when :communications
          (1..@max_communications).step do |i|
            collection << "Message #{i} Text Identifier"
            collection << "Message #{i} Type"
            collection << "Message #{i} Sent"
            collection << "Message #{i} Status"
          end
        when :appointments
          (1..@max_appointments).step do |i|
            collection << "Appointment #{i} Creation Date"
            collection << "Appointment #{i} Date"
            collection << "Followup #{i} Date"
            collection << "Days To Visit #{i}"
            collection << "BP Recorded At Visit #{i}"
            collection << "Patient Visited Facility #{i}"
            collection << "Followup #{i} Facility Type"
            collection << "Followup #{i} Facility State"
            collection << "Followup #{i} Facility District"
            collection << "Followup #{i} Facility Block"
          end
        when :encounters
          (1..@max_past_visits).step do |i|
            collection << "Encounter #{i} Date"
          end
        else
          collection << key.to_s.split("_").each(&:capitalize!).join(" ")
        end
      end
    end

    def create_csv
      CSV.generate(headers: true) do |csv|
        csv << headers
        aggregate.each {|patient_data| csv << patient_data.values.flatten }
      end
    end
  end
end