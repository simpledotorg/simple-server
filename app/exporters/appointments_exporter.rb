module AppointmentsExporter
  def self.csv(appointments)
    patients = appointments.sort_by { |a| [a.patient.risk_priority, a.days_overdue] }.map(&:patient)
    PatientsExporter.csv(patients)
  end
end
