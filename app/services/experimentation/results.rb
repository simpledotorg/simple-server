module Experimentation
  class Results
    EXPANDABLE_COLUMNS = ["Communications", "Appointments", "Blood Pressures"].freeze
    FOLLOWUP_CUTOFF = 10.days

    attr_reader :experiment, :patient_data_aggregate, :query_date_range

    def initialize(experiment_name)
      @experiment = Experimentation::Experiment.find_by!(name: experiment_name)
      @patient_data_aggregate = []

      start_date = experiment.start_date - 1.year
      end_date = experiment.end_date + FOLLOWUP_CUTOFF
      @query_date_range = start_date..end_date
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
            "Appointments" => appointments(patient),
            "Blood Pressures" => blood_pressures(patient),
            "Communications" => experimental_communications(notifications),
            "Patient Gender" => patient.gender,
            "Patient Age" => patient.age,
            "Patient Risk Level" => patient.risk_priority,
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

    private

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
  end
end
