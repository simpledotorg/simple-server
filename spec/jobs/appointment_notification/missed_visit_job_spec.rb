require "rails_helper"

RSpec.describe AppointmentNotification::MissedVisitJob, type: :job do
  let!(:ihci) { create(:organization, name: "IHCI") }
  let!(:path) { create(:organization, name: "PATH") }
  let!(:ihci_facility_group) { create(:facility_group, organization: ihci) }
  let!(:path_facility_group) { create(:facility_group, organization: path) }
  let!(:ihci_facility) { create(:facility, facility_group: ihci_facility_group) }
  let!(:path_facility) { create(:facility, facility_group: path_facility_group) }
  let!(:overdue_appointments_from_ihci) { create_list(:appointment, 2, :overdue, facility: ihci_facility) }
  let!(:overdue_appointments_from_path) { create_list(:appointment, 2, :overdue, facility: path_facility) }
  let!(:all_overdue_appointments) { overdue_appointments_from_ihci + overdue_appointments_from_path }

  before do
    allow_any_instance_of(AppointmentNotification::Worker).to receive(:perform)

    allow(FeatureToggle).to receive(:enabled?).with("APPOINTMENT_REMINDERS").and_return(true)
  end

  it "should send reminders to all organizations in env" do
    Organization.all.each do |org|
      expect(AppointmentNotificationService).to receive(:send_after_missed_visit).with(appointments: org.appointments)
    end

    described_class.perform_now
  end
end
