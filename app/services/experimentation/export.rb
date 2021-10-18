module Experimentation
  class Export
    require "csv"

    EXPANDABLE_COLUMNS = ["Followups", "Communications", "Appointments", "Blood Pressures"].freeze
    FOLLOWUP_START = 3.days
    FOLLOWUP_CUTOFF = 10.days

    attr_reader :experiment, :patient_data_aggregate, :query_date_range

    def initialize(experiment)
      @experiment = experiment
      @patient_data_aggregate = []

      start_time = experiment.start_time - 1.year
      end_time = experiment.end_time + FOLLOWUP_CUTOFF
      @query_date_range = start_time.to_date..end_time.to_date
      aggregate_data
    end

    def write_csv
      file_location = "/tmp/" + experiment.name.downcase.tr(" ", "_") + ".csv"
      File.write(file_location, csv_data)
    end

    private

    def csv_data
      CSV.generate(headers: true) do |csv|
        csv << headers
        patient_data_aggregate.each do |patient_data|
          EXPANDABLE_COLUMNS.each do |column|
            patient_data[column].each { |column_data| patient_data.merge!(column_data) }
          end
          csv << patient_data
        end
      end
    end

    def aggregate_data
      experiment.treatment_groups.each do |group|
        group.patients.each do |patient|
          tgm = patient.treatment_group_memberships.find_by(treatment_group_id: group.id)
          notifications = patient.notifications.where(experiment_id: experiment.id).order(:remind_on)
          assigned_facility = patient.assigned_facility

          patient_data_aggregate << {
            "Experiment Name" => experiment.name,
            "Treatment Group" => group.description,
            "Experiment Inclusion Date" => tgm.created_at.to_date,
            "Followups" => followup_results(patient, tgm, notifications),
            "Appointments" => appointments(patient),
            "Blood Pressures" => blood_pressures(patient),
            "Communications" => experimental_communications(notifications),
            "Patient Gender" => patient.gender,
            "Patient Age" => patient.age,
            "Patient Risk Level" => patient.high_risk? ? "High" : "Normal",
            "Assigned Facility Name" => assigned_facility&.name,
            "Assigned Facility Type" => assigned_facility&.facility_type,
            "Assigned Facility State" => assigned_facility&.state,
            "Assigned Facility District" => assigned_facility&.district,
            "Assigned Facility Block" => assigned_facility&.block,
            "Patient Registration Date" => patient.device_created_at.to_date,
            "Patient Id" => tgm.id
          }
        end
      end
    end

    def experimental_communications(notifications)
      index = 1
      notifications.each_with_object([]) do |notification, communications|
        ordered_communications = notification.communications.order(:device_created_at)
        ordered_communications.each do |comm|
          communications << {
            "Message #{index} Type" => comm.communication_type,
            "Message #{index} Date Sent" => comm.detailable&.delivered_on&.to_date,
            "Message #{index} Status" => comm.detailable&.result,
            "Message #{index} Text Identifier" => notification.message
          }
          index += 1
        end
      end
    end

    def followup_results(patient, tgm, notifications)
      if experiment.experiment_type == "current_patients"
        active_patient_followups(patient, notifications)
      elsif experiment.experiment_type == "stale_patients"
        stale_patient_followups(patient, tgm)
      else
        raise ArgumentError("No followup logic available for experiment type #{experiment.experiment_type}")
      end
    end

    def active_patient_experimental_appointment_dates(patient, notifications)
      if notifications.any?
        notifications.map(&:subject).pluck(:scheduled_date).uniq
      else
        # control patients don't have notifications
        experiment_date_range = (experiment.start_time..experiment.end_time)
        patient.appointments.where(scheduled_date: experiment_date_range)
          .where("device_created_at < ?", experiment.start_time.beginning_of_day)
          .order(:scheduled_date)
          .pluck(:scheduled_date)
          .uniq
      end
    end

    def active_patient_followups(patient, notifications)
      appointment_dates = active_patient_experimental_appointment_dates(patient, notifications)
      appointment_dates.map.each_with_index do |appointment_date, index|
        adjusted_index = index + 1
        followup_date_range = ((appointment_date - FOLLOWUP_START)..(appointment_date + FOLLOWUP_CUTOFF))
        followup_date = patient.blood_pressures.where(device_created_at: followup_date_range).order(:device_created_at).first&.device_created_at&.to_date
        days_to_followup = followup_date.nil? ? nil : (followup_date - appointment_date).to_i
        {
          "Experiment Appointment #{adjusted_index} Date" => appointment_date,
          "Followup #{adjusted_index} Date" => followup_date,
          "Days to visit #{adjusted_index}" => days_to_followup
        }
      end
    end

    def stale_patient_followups(patient, tgm)
      date_added = tgm.created_at.to_date
      followup_date_range = (date_added..(date_added + FOLLOWUP_CUTOFF))
      followup_date = patient.blood_pressures.where(device_created_at: followup_date_range).order(:device_created_at).first&.device_created_at&.to_date
      days_to_followup = followup_date.nil? ? nil : (followup_date - date_added).to_i
      [{
        "Followup Date" => followup_date,
        "Days to visit" => days_to_followup
      }]
    end

    def appointments(patient)
      appointments = patient.appointments.where(status: ["visited", "scheduled"], scheduled_date: query_date_range).order(:scheduled_date)
      appointments.each_with_index.map do |appt, index|
        adjusted_index = index + 1
        {"Appointment #{adjusted_index} Creation Date" => appt.device_created_at.to_date, "Appointment #{adjusted_index} Date" => appt.scheduled_date}
      end
    end

    def blood_pressures(patient)
      bp_dates = patient.blood_pressures.where(device_created_at: query_date_range).order(:device_created_at).pluck(:device_created_at).map(&:to_date)
      bp_dates.each_with_index.map do |bp_date, index|
        adjusted_index = index + 1
        {"Blood Pressure #{adjusted_index} Date" => bp_date}
      end
    end

    def headers
      keys = patient_data_aggregate.first.keys
      keys.map do |key|
        if key.in?(EXPANDABLE_COLUMNS)
          largest_entry = patient_data_aggregate.max { |a, b| a[key].length <=> b[key].length }
          largest_entry[key].map(&:keys)
        else
          key
        end
      end.flatten
    end
  end
end
