module Experimentation
  class DataExport

    attr_reader :experiment, :max_communications, :max_appointments, :max_encounters

    def initialize(name)
      @experiment = Experimentation::Experiment.find_by!(name: name)
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
            appointments: process_appointments(notifications),
            encounters: encounters(patient),
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

    def process_appointments(notifications)
      appts = notifications.map(&:subject).uniq.sort_by{|appt| appt.scheduled_date }
      @max_appointments = appts.count if appts.count > max_appointments
      appts.map do |appt|
        [appt.device_created_at.to_date, appt.scheduled_date]
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
          patient_data[:appointments] << [nil, nil]
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