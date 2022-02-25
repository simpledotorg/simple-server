class Notifications::ExperimentalAppointmentReminder < Notification
  def message_data
    return unless patient

    facility = subject&.facility || patient.assigned_facility
    { message: message,
      vars: { facility_name: facility.name,
              patient_name: patient.full_name,
              appointment_date: subject&.scheduled_date&.strftime("%d-%m-%Y") },
      locale: facility.locale }
  end
end
