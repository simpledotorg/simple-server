module Experimentation
  class DataExport
    require "csv"

    FOLLOWUP_CUTOFF = 10.days

    attr_reader :experiment, :aggregate, :query_date_range

    def initialize(experiment_name)
      @experiment = Experimentation::Experiment.find_by!(name: experiment_name)
      @recipient_email_address = recipient_email_address
      remind_ons = experiment.reminder_templates.pluck(:remind_on_in_days)
      @aggregate = []

      start_date = experiment.start_date - 1.year
      end_date = experiment.end_date + FOLLOWUP_CUTOFF
      @query_date_range = start_date..end_date
    end

    def as_csv
      aggregate_data
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
            "Experiment Name": experiment.name,
            "Treatment Group": group.description,
            "Experiment Inclusion Date": tgm.created_at.to_date,
            "Appointments": appointments(patient),
            "Encounters": past_visits(patient),
            "Communications": experimental_communications(notifications),
            "Patient Gender": patient.gender,
            "Patient Age": patient.age,
            "Patient Risk Level": patient.risk_priority,
            "Assigned Facility Name": assigned_facility&.name,
            "Assigned Facility Type": assigned_facility&.facility_type,
            "Assigned Facility State": assigned_facility&.state,
            "Assigned Facility District": assigned_facility&.district,
            "Assigned Facility Block": assigned_facility&.block,
            "Patient Registration Date": patient.device_created_at.to_date,
            "Patient Id": tgm.id
          }
        end
      end
    end

    def experimental_communications(notifications)
      notifications.map do |notification|
        ordered_communications = notification.communications.order(:device_created_at)
        ordered_communications.each_with_index do |comm, index|
          adjusted_index = index + 1
          {
            "Message #{adjusted_index} Type" => comm.communication_type,
            "Message #{adjusted_index} Date Sent" => comm.detailable&.delivered_on&.to_date,
            "Message #{adjusted_index} Status" => comm.detailable&.result,
            "Message #{adjusted_index} Text Identifier" => notification.message
          }
        end
      end
    end

    def pad_communications
      aggregate.each do |patient_data|
        communications_deficit = @max_communications - patient_data[:communications].count
        communications_deficit.times do
          patient_data[:communications] << Array.new(4, nil)
        end
      end
    end

    def appointments(patient)
      appointments = patient.appointments.where(status: ["visited", "scheduled"], scheduled_date: query_date_range)
      appointments.each_with_index.map do |appt, index|
        adjusted_index = index + 1
        { "Appointment #{adjusted_index} Creation Date" => appt.device_created_at, "Appointment #{adjusted_index} Date" => appt.scheduled_date }
      end
    end

    def past_visits(patients)
      bp_dates = patient.blood_pressures.where(device_created_at: query_date_range).order(:device_created_at).pluck(:device_created_at).map(&:to_date)
      bp_dates.each_with_index.map do |bp_date, index|
        adjusted_index = index + 1
        { "Blood Pressure #{adjusted_index} Date" => bp_date }
      end
    end

    def headers
      keys = aggregate.first.keys
      keys.each_with_object([]) do |key, collection|
        case key
        when :communications
          (1..@max_communications).step do |i|
            collection << "Message #{i} Type"
            collection << "Message #{i} Sent"
            collection << "Message #{i} Status"
            collection << "Message #{i} Text Identifier"
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
        aggregate.each { |patient_data| csv << patient_data.values.flatten }
      end
    end

    def mail_csv
      mailer = ApplicationMailer.new
      email_params = {
        to: recipient_email_address,
        subject: "Experiment data export: #{experiment.name}",
        content_type: "multipart/mixed",
        body: "Please see attached CSV."
      }
      email = mailer.mail(email_params)
      filename = experiment.name.gsub(" ", "_")
      email.attachments[filename] = {
        mime_type: "text/csv",
        content: csv
      }
      email.deliver
    end
  end
end
